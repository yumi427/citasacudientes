import json
import os
import uuid
import datetime
import boto3
from botocore.exceptions import ClientError

TABLE_NAME = os.environ.get("TABLE_NAME")
dynamodb_client = boto3.client("dynamodb")

def build_response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,Authorization",
            "Access-Control-Allow-Methods": "POST,OPTIONS"
        },
        "body": json.dumps(body)
    }

def handler(event, context):
    """
    Agendamiento transaccional de citas (Anti-Overbooking):
    POST /citas
    Payload: {
        "profesorId": "P101",
        "acudienteId": "ACU-501",
        "acudienteNombre": "Yoimer Barrera",
        "estudiante": "Laura Barrera",
        "grado": "5A",
        "fecha": "2026-11-20",
        "hora": "14:00",
        "motivo": "Rendimiento académico periodo 3"
    }
    """
    try:
        body = json.loads(event.get("body") or "{}")

        required_fields = ["profesorId", "acudienteId", "estudiante", "fecha", "hora", "motivo"]
        for field in required_fields:
            if not body.get(field):
                return build_response(400, {"error": f"El campo '{field}' es obligatorio."})

        cita_id = str(uuid.uuid4())
        timestamp = datetime.datetime.utcnow().isoformat()

        profesor_id = body["profesorId"]
        acudiente_id = body["acudienteId"]
        fecha = body["fecha"]
        hora = body["hora"]

        # Operación Transaccional ACID en DynamoDB:
        # 1. Insertar la cita si no existe
        # 2. Bloquear la franja horaria del docente SOLO si sigue en estado "LIBRE"
        transact_items = [
            {
                "Put": {
                    "TableName": TABLE_NAME,
                    "Item": {
                        "PK": {"S": f"CITA#{cita_id}"},
                        "SK": {"S": "METADATA"},
                        "GSI1_PK": {"S": f"ACUDIENTE#{acudiente_id}"},
                        "GSI1_SK": {"S": f"FECHA#{fecha}T{hora}"},
                        "GSI2_PK": {"S": "ESTADO#SOLICITADA"},
                        "GSI2_SK": {"S": f"FECHA#{fecha}T{hora}"},
                        "citaId": {"S": cita_id},
                        "profesorId": {"S": profesor_id},
                        "acudienteId": {"S": acudiente_id},
                        "acudienteNombre": {"S": body.get("acudienteNombre", "Acudiente")},
                        "estudiante": {"S": body["estudiante"]},
                        "grado": {"S": body.get("grado", "General")},
                        "fecha": {"S": fecha},
                        "hora": {"S": hora},
                        "motivo": {"S": body["motivo"]},
                        "estado": {"S": "SOLICITADA"},
                        "creadoEn": {"S": timestamp}
                    },
                    "ConditionExpression": "attribute_not_exists(PK)"
                }
            },
            {
                "Update": {
                    "TableName": TABLE_NAME,
                    "Key": {
                        "PK": {"S": f"DOCENTE#{profesor_id}"},
                        "SK": {"S": f"SLOT#{fecha}#{hora}"}
                    },
                    "UpdateExpression": "SET estado = :reservado, citaId = :cid",
                    "ConditionExpression": "attribute_exists(PK) AND estado = :libre",
                    "ExpressionAttributeValues": {
                        ":reservado": {"S": "RESERVADO"},
                        ":libre": {"S": "LIBRE"},
                        ":cid": {"S": cita_id}
                    }
                }
            }
        ]

        dynamodb_client.transact_write_items(TransactItems=transact_items)

        return build_response(201, {
            "mensaje": "Cita agendada exitosamente",
            "citaId": cita_id,
            "estado": "SOLICITADA",
            "fecha": fecha,
            "hora": hora,
            "profesorId": profesor_id,
            "estudiante": body["estudiante"]
        })

    except ClientError as e:
        code = e.response.get("Error", {}).get("Code")
        if code == "TransactionCanceledException":
            return build_response(409, {
                "error": "Conflicto: El horario seleccionado ya no se encuentra disponible. Por favor elija otra hora."
            })
        return build_response(500, {"error": f"Error de DynamoDB: {str(e)}"})

    except Exception as e:
        return build_response(500, {"error": str(e)})
