# GCP-FinTech-Guard-Native: Arquitectura Modular en la Nube con Guardrails de FinOps

**Léelo en:** [English](README.md) | [Español](README.es.md) | [Italiano](README.it.md)

## 🎯 Resumen
**GCP-FinTech-Guard-Native** reimplementa la misma base de seguridad y FinOps que su proyecto hermano en otra nube principal, reestructurada en módulos de Terraform reutilizables con un guardrail de FinOps, orientado a la presión de costos y cumplimiento típica de una carga de trabajo de servicios financieros.

## 💡 Qué Agrega Este Proyecto
* **Arquitectura modular:** `/modules/network`, `/modules/security`, `/modules/finops` en lugar de archivos `.tf` planos en la raíz — cada responsabilidad es revisable y reutilizable de forma independiente, algo que importa cada vez más a medida que el código crece entre equipos.
* **FinOps como código:** un Billing Budget con cuatro umbrales de notificación progresivos (50%, 75%, 90% de gasto real, más una alerta de 100% *pronosticado*), en lugar de una única advertencia tardía.
* **La misma base reforzada, heredada:** reglas de firewall explícitas de denegación por defecto en ambas direcciones, un secreto de Secret Manager con IAM restringido, y un guardrail de ciclo de vida `prevent_destroy` en lugar de la ventana de soft-delete/purge-protection del proyecto original.

## 🛡️ Lo Que Realmente Está Implementado
* **Firewall de VPC, ambas direcciones:** reglas explícitas de permiso para HTTPS (443) entrante y saliente, con una regla de denegación total al final de cada dirección, aplicada a nivel de VPC (GCP no tiene un paso de asociación NSG-a-subred — las reglas de firewall se adjuntan directamente a la red).
* **Secret Manager, reforzado:** `roles/secretmanager.admin` acotado a un único principal desplegador nombrado (sin concesión amplia a nivel de proyecto), replicación automática, y `lifecycle { prevent_destroy = true }` en el contenedor del secreto.
* **Budget de FinOps, progresivo:** cuatro notificaciones en lugar de una — tres umbrales de gasto real (50/75/90%) y uno de gasto pronosticado (100%), entregadas mediante canales de notificación por correo de Cloud Monitoring por dirección, todo conectado a través de variables de Terraform en lugar de valores fijos.
* **Sin secretos ni IDs hardcodeados:** `billing_account_id`, `deployer_principal` y `budget_alert_emails` son variables requeridas sin valor por defecto, provistas vía variables de entorno `TF_VAR_*` en CI o un `terraform.tfvars` local excluido de Git. Ver `terraform.tfvars.example`.

## ⚠️ Dónde Esto Difiere Genuinamente del Proyecto Original
Dos guardrails no tienen un equivalente exacto en esta plataforma, y se señalan aquí en lugar de reproducirse silenciosamente:

1. **Protección contra eliminación.** La purge-protection del Key Vault del proyecto original otorga una ventana de retención de soft-delete que sobrevive incluso a una llamada de eliminación. Secret Manager no tiene equivalente: una versión de secreto destruida desaparece de inmediato. `prevent_destroy` en este módulo es un control de proceso a nivel de Terraform (bloquea que `terraform destroy`/`apply` elimine el recurso a menos que se edite primero el bloque lifecycle) — no es una ventana de recuperación forzada por la plataforma. No lo trates como tal.
2. **Aislamiento de red privada.** El `public_network_access_enabled = false` + las ACLs de red de denegación por defecto del proyecto original restringen el plano de datos del Key Vault a redes de confianza. El equivalente más cercano en GCP es un perímetro de VPC Service Controls a nivel de organización, fuera del alcance de un módulo raíz de Terraform a nivel de proyecto. Registrado más abajo como ítem del roadmap, igual que en la plataforma original.

## 🏗️ Desglose de Componentes
### Raíz
**`main.tf`** — orquesta los tres módulos siguientes (no hay contenedor equivalente a un resource group que crear; se asume que `var.project_id` ya existe).
**`variables.tf`** — entradas de todo el proyecto, incluyendo parámetros de FinOps (sin valores por defecto para el ID de facturación, el principal desplegador, ni los correos de alerta, por diseño).
**`providers.tf`** — configuración de Terraform y del provider `google`.
**`outputs.tf`** — agrega las salidas de cada módulo.

### `modules/network`
VPC, subred, y cuatro reglas de firewall (permiso HTTPS + denegación total, ambas direcciones).

### `modules/security`
Secreto de Secret Manager con replicación automática, binding de IAM restringido, y un guardrail de ciclo de vida `prevent_destroy`.

### `modules/finops`
El billing budget con umbrales progresivos y canales de notificación por correo por destinatario, parametrizado por ID de facturación, ID de proyecto, monto/moneda del presupuesto, y correos de alerta.

---

## 🛠️ Stack Tecnológico
* **Nube:** Google Cloud Platform (VPC, Secret Manager, Cloud Billing Budgets, canales de notificación de Cloud Monitoring)
* **IaC:** HashiCorp Terraform (provider `google` ~> 5.0), estructura modular
* **Escaneo de Seguridad:** Checkov (bloqueante, `soft_fail: false`)
* **CI/CD:** GitHub Actions con Workload Identity Federation (sin claves de service account de larga duración)
* **Control de Versiones:** Git (GitHub)

## 🤖 Pipeline de CI/CD
El pipeline ejecuta, en orden: login por Workload Identity Federation → `terraform init` → `terraform fmt -check -recursive` → `terraform validate` → escaneo de seguridad con Checkov (bloqueante) → `terraform plan` → `terraform apply` (solo en `main`).

Secrets requeridos en el repo de GitHub: `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_SERVICE_ACCOUNT`, `GCP_BILLING_ACCOUNT_ID`, `BUDGET_ALERT_EMAILS`.

[![Terraform CI/CD](https://github.com/luis-troccoli/gcp-fintech-guard-native/actions/workflows/terraform-pipeline.yml/badge.svg)](https://github.com/luis-troccoli/gcp-fintech-guard-native/actions/workflows/terraform-pipeline.yml)

## 📈 Roadmap
* **Org Policy:** monitoreo continuo de cumplimiento, en paralelo con el ítem de Azure Policy del proyecto original.
* **VPC Service Controls:** un perímetro de red real alrededor del secreto de Secret Manager, cerrando la brecha señalada arriba.
* **Backend remoto:** un bucket de GCS con bloqueo de estado (aún pendiente, la misma brecha que el ítem de backend remoto del proyecto original).

## 🚀 Guía de Despliegue
1. Copia `terraform.tfvars.example` a `terraform.tfvars` y provee tu ID de proyecto de GCP, ID de cuenta de facturación, principal desplegador, y correo(s) de alerta de presupuesto.
2. `terraform init`
3. `terraform validate` / `terraform plan` — recomendado antes de cualquier apply, para revisar los cambios exactos.
4. `terraform apply` — en este repo, este paso corre automáticamente vía el pipeline de CI/CD en cada push a `main` (ver arriba). Para despliegues manuales/locales fuera de CI, ejecútalo directamente contra tu propio state.
5. `terraform destroy` al terminar, para evitar costos no deseados. Nota: este proyecto todavía no usa un backend de estado remoto (ver roadmap), así que el state es local al entorno donde se corrió el apply — mantén las ejecuciones locales y de CI desde la misma fuente de verdad para evitar drift.

## 🤝 Contribución
Abierto a PRs y discusión de arquitectura de cualquiera que trabaje en seguridad en la nube o FinOps.