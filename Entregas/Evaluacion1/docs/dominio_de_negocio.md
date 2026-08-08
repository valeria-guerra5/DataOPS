# Dominio de negocio — Taller de reparación de bicicletas "Rueda Libre"

## Descripción

"Rueda Libre" es un taller mecánico especializado en mantenimiento y reparación de
bicicletas. Cada **cliente** puede tener registradas una o varias **bicicletas**, y cada vez
que trae una a revisión se abre una **orden de servicio** asignada a un **técnico**. Una
orden agrupa uno o más **servicios** de un catálogo fijo (ajuste de frenos, cambio de
cadena, verdadeo de rueda, etc.) y, opcionalmente, **repuestos** del inventario del taller
(pastillas de freno, cámaras, cadenas...) que se consumen en esa reparación. Además, los
clientes pueden agendar una **cita** previa para asegurar turno antes de dejar la bicicleta.

El modelo resuelve el mismo tipo de pregunta operativa que un taller real necesita
responder todos los días: qué bicicletas están en reparación, cuánto cuesta cada orden
(mano de obra + repuestos), qué técnico atendió cada trabajo, y qué repuestos hay que
reponer en inventario.

## Por qué este dominio

Es un dominio con jerarquía real de al menos dos niveles (`clientes → bicicletas → órdenes
de servicio → detalle de servicios / repuestos`), volumen de datos naturalmente pequeño
(un taller mediano no supera unos pocos miles de órdenes al año) y reglas de negocio con
peso propio (cálculo de totales, control de stock, estados de una orden) que justifican
tanto migraciones evolutivas como una función repetible — sin depender de Parch & Posey ni
de otro proyecto visto en clase.

## Modelo transaccional

- **clientes** — dueños de las bicicletas.
- **bicicletas** — pertenecen a un cliente (1 cliente → N bicicletas).
- **tecnicos** — mecánicos del taller que atienden órdenes.
- **servicios** — catálogo de servicios ofrecidos (precio base, duración estimada).
- **repuestos** — inventario de piezas (precio unitario, stock disponible).
- **ordenes_servicio** — una intervención sobre una bicicleta, asignada a un técnico.
- **orden_servicio_detalle** — servicios aplicados dentro de una orden (N a N entre
  `ordenes_servicio` y `servicios`, con precio congelado al momento de la orden).
- **orden_repuestos** — repuestos consumidos dentro de una orden (N a N entre
  `ordenes_servicio` y `repuestos`, con precio congelado y cantidad).
- **citas** — turno agendado por un cliente para una bicicleta, antes de convertirse en
  orden de servicio (agregada en una migración evolutiva posterior al baseline).

## Diagrama entidad-relación

```mermaid
erDiagram
    CLIENTES ||--o{ BICICLETAS : posee
    CLIENTES ||--o{ CITAS : agenda
    BICICLETAS ||--o{ ORDENES_SERVICIO : "es intervenida en"
    BICICLETAS ||--o{ CITAS : "se agenda para"
    TECNICOS ||--o{ ORDENES_SERVICIO : atiende
    TECNICOS ||--o{ CITAS : recibe
    ORDENES_SERVICIO ||--o{ ORDEN_SERVICIO_DETALLE : incluye
    SERVICIOS ||--o{ ORDEN_SERVICIO_DETALLE : "es aplicado en"
    ORDENES_SERVICIO ||--o{ ORDEN_REPUESTOS : consume
    REPUESTOS ||--o{ ORDEN_REPUESTOS : "es usado en"

    CLIENTES {
        int cliente_id PK
        varchar nombre
        varchar email
        varchar telefono
        date fecha_registro
        varchar nivel_fidelidad "agregada en V3"
    }
    BICICLETAS {
        int bicicleta_id PK
        int cliente_id FK
        varchar marca
        varchar modelo
        varchar tipo
        varchar numero_serie
        varchar estado "agregada en V5, corregida en V6"
    }
    TECNICOS {
        int tecnico_id PK
        varchar nombre
        varchar especialidad
        date fecha_contratacion
    }
    SERVICIOS {
        int servicio_id PK
        varchar nombre
        text descripcion
        numeric precio_base
        int duracion_estimada_min
    }
    REPUESTOS {
        int repuesto_id PK
        varchar nombre
        varchar categoria
        numeric precio_unitario
        int stock
    }
    ORDENES_SERVICIO {
        int orden_id PK
        int bicicleta_id FK
        int tecnico_id FK
        date fecha_ingreso
        date fecha_entrega_estimada
        date fecha_entrega_real
        varchar estado
        numeric total
        text notas "agregada en V3"
    }
    ORDEN_SERVICIO_DETALLE {
        int detalle_id PK
        int orden_id FK
        int servicio_id FK
        int cantidad
        numeric precio_aplicado
    }
    ORDEN_REPUESTOS {
        int orden_repuesto_id PK
        int orden_id FK
        int repuesto_id FK
        int cantidad
        numeric precio_aplicado
    }
    CITAS {
        int cita_id PK
        int cliente_id FK
        int bicicleta_id FK
        int tecnico_id FK
        timestamp fecha_hora
        varchar estado
    }
```

## Volumen de datos

Datos sintéticos generados en el baseline: ~40 clientes, ~60 bicicletas, 6 técnicos, 12
servicios de catálogo, 20 repuestos, ~150 órdenes de servicio con su detalle. Muy por debajo
del tier gratuito de Neon (0.5 GB).
