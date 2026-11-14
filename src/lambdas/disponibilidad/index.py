import json
import os
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
            "Access-Control-Allow-Methods": "GET,POST,OPTIONS"
        },
        "body": json.dumps(body)
    }

def handler(event, context):
    """
    Gestiona la disponibilidad de los docentes:
    - GET /disponibilidad?profesorId=...&fecha=...
    - POST /disponibilidad (Publicar franjas horarias)
    """
    http_method = event.get("requestContext", {}).get("http", {}).get("method", "GET")

    try:
        if http_method == "GET":
            params = event.get("queryStringParameters") or {}
            profesor_id = params.get("profesorId")

            if not profesor_id:
                return build_response(400, {"error": "Falta el parámetro 'profesorId'"})

            fecha = params.get("fecha")
            key_condition = Key("PK").eq(f"DOCENTE#{profesor_id}")
            if fecha:
                key_condition = key_condition & Key("SK").begins_with(f"SLOT#{fecha}")
            else:
                key_condition = key_condition & Key("SK").begins_with("SLOT#")

            result = table.query(
                KeyConditionExpression=key_condition
            )
            items = result.get("Items", [])
            # Filtrar franjas que sigan libres
            libres = [item for item in items if item.get("estado") == "LIBRE"]

            return build_response(200, {
                "profesorId": profesor_id,
                "disponibles": libres,
                "total": len(libres)
            })

        elif http_method == "POST":
            body = json.loads(event.get("body") or "{}")
            profesor_id = body.get("profesorId")
            fecha = body.get("fecha")       # YYYY-MM-DD
            hora = body.get("hora")         # HH:MM
            aula = body.get("aula", "Sala de Docentes")

            if not (profesor_id and fecha and hora):
                return build_response(400, {"error": "Campos requeridos: profesorId, fecha, hora"})

            item = {
                "PK": f"DOCENTE#{profesor_id}",
                "SK": f"SLOT#{fecha}#{hora}",
                "profesorId": profesor_id,
                "fecha": fecha,
                "hora": hora,
                "aula": aula,
                "estado": "LIBRE"
            }

            table.put_item(Item=item)
            return build_response(201, {
                "mensaje": "Franja horaria publicada exitosamente",
                "slot": item
            })

        return build_response(405, {"error": "Método no permitido"})

    except Exception as e:
        return build_response(500, {"error": str(e)})
