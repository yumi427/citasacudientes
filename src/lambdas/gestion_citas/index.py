import json
import os
import datetime
import boto3
from boto3.dynamodb.conditions import Key

TABLE_NAME = os.environ.get("TABLE_NAME")
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)

def build_response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,Authorization",
            "Access-Control-Allow-Methods": "GET,PATCH,OPTIONS"
        },
        "body": json.dumps(body)
    }

def handler(event, context):
    """
    Gestión y seguimiento de citas:
    - GET /citas?acudienteId=... | estado=...
    - GET /citas/{id}
    - PATCH /citas/{id} (Aceptar, cancelar, registrar compromisos de acta)
    """
    http_method = event.get("requestContext", {}).get("http", {}).get("method", "GET")
    path_params = event.get("pathParameters") or {}
    cita_id = path_params.get("id")

    try:
        if http_method == "GET":
            if cita_id:
                response = table.get_item(Key={"PK": f"CITA#{cita_id}", "SK": "METADATA"})
                item = response.get("Item")
                if not item:
                    return build_response(404, {"error": "Cita no encontrada"})
                return build_response(200, item)

            query_params = event.get("queryStringParameters") or {}
            acudiente_id = query_params.get("acudienteId")
            estado = query_params.get("estado")

            if acudiente_id:
                result = table.query(
                    IndexName="GSI1",
                    KeyConditionExpression=Key("GSI1_PK").eq(f"ACUDIENTE#{acudiente_id}")
                )
                return build_response(200, {"citas": result.get("Items", [])})

            elif estado:
                result = table.query(
                    IndexName="GSI2",
                    KeyConditionExpression=Key("GSI2_PK").eq(f"ESTADO#{estado.upper()}")
                )
                return build_response(200, {"citas": result.get("Items", [])})

            return build_response(400, {"error": "Se requiere acudienteId o estado para filtrar"})

        elif http_method == "PATCH":
            if not cita_id:
                return build_response(400, {"error": "Se requiere el ID de la cita"})

            body = json.loads(event.get("body") or "{}")
            nuevo_estado = body.get("estado")
            compromisos = body.get("compromisos")
            aula = body.get("aula")

            update_expressions = []
            expression_attr_values = {}
            expression_attr_names = {}

            if nuevo_estado:
                update_expressions.append("#est = :estado")
                update_expressions.append("GSI2_PK = :gsi2")
                expression_attr_names["#est"] = "estado"
                expression_attr_values[":estado"] = nuevo_estado.upper()
                expression_attr_values[":gsi2"] = f"ESTADO#{nuevo_estado.upper()}"

            if compromisos:
                update_expressions.append("compromisos = :comp")
                expression_attr_values[":comp"] = compromisos

            if aula:
                update_expressions.append("aula = :aula")
                expression_attr_values[":aula"] = aula

            update_expressions.append("actualizadoEn = :act")
            expression_attr_values[":act"] = datetime.datetime.utcnow().isoformat()

            if not update_expressions:
                return build_response(400, {"error": "No se enviaron campos para actualizar"})

            update_expr_str = "SET " + ", ".join(update_expressions)

            response = table.update_item(
                Key={"PK": f"CITA#{cita_id}", "SK": "METADATA"},
                UpdateExpression=update_expr_str,
                ExpressionAttributeValues=expression_attr_values,
                ExpressionAttributeNames=expression_attr_names if expression_attr_names else None,
                ReturnValues="ALL_NEW"
            )

            return build_response(200, {
                "mensaje": "Cita actualizada correctamente",
                "cita": response.get("Attributes")
            })

        return build_response(405, {"error": "Método no soportado"})

    except Exception as e:
        return build_response(500, {"error": str(e)})
