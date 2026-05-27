# Fleet Asset Maintenance Tracker
 
> **Platform:** SAP BTP ABAP Environment (SAP ABAP Cloud).

> **Language:** Modern ABAP Syntax.

> **Development Tool:** ABAP Development Tools (ADT) for Eclipse.

> **Architecture:** SAP RESTful Application Programming Model (RAP) — Managed Scenario, Draft-Enabled.

> **OData Version:** OData V4.

> **UI:** SAP Fiori Elements (List Report + Object Page).
 
---
 
## Table of Contents
 
1. [Project Overview](#1-project-overview)
2. [Architecture Summary](#2-architecture-summary)
3. [Database Layer](#3-database-layer)
   - [Data Dictionary Objects](#31-data-dictionary-objects)
   - [Database Tables](#32-database-tables)
4. [Numbering Strategy](#4-numbering-strategy)
5. [CDS View Layer](#5-cds-view-layer)
   - [Interface Views](#51-interface-views)
   - [Projection Views](#52-projection-views)
   - [Value Help Views](#53-value-help-views)
6. [Metadata Extensions](#6-metadata-extensions)
7. [Behavior Definition Layer](#7-behavior-definition-layer)
   - [Interface BDEF](#71-interface-bdef)
   - [Projection BDEF](#72-projection-bdef)
8. [Behavior Implementation](#8-behavior-implementation)
   - [Early Numbering](#81-early-numbering)
   - [Determinations](#82-determinations)
   - [Validations](#83-validations)
   - [Actions](#84-actions)
   - [Instance Feature Control](#85-instance-feature-control)
9. [Draft Handling](#9-draft-handling)
10. [Service Definition and Binding](#10-service-definition-and-binding)
11. [State Machine Reference](#11-state-machine-reference)
---
 
## 1. Project Overview
 
The **Fleet Asset Maintenance Tracker** is a full-stack SAP ABAP Cloud application built on the **SAP RESTful Application Programming Model (RAP)**. It enables a company to manage its fleet of vehicles and machines through their complete operational lifecycle — from acquisition through active service, repair events, and eventual retirement.
 
The application exposes a **Fiori Elements List Report and Object Page** via OData V4, allowing users to:
 
- Create and manage vehicle records with structured metadata
- Track maintenance events (repairs, inspections, scheduled services) as child log entries against each vehicle
- Drive vehicles through a controlled **status state machine** using dedicated UI actions
- Save work-in-progress as **drafts** without committing incomplete records to the database
- Enforce **field-level read-only rules** once a vehicle reaches Retired status
- Block illegal operations via **server-side validations** — most notably preventing retirement of a vehicle that still carries open maintenance tasks
The project demonstrates a production-grade RAP implementation covering the full stack: dictionary objects, interface and consumption CDS views, metadata extensions, behavior definitions, behavior implementation classes, and service exposure.
 
---
 
## 2. Architecture Summary
 
The application follows the standard RAP layered architecture:
 
```
┌─────────────────────────────────────────────────────────┐
│                  CONSUMPTION LAYER                      │
│   ZFLEET_C_VEHICLE (Projection View + BDEF)             │
│   ZFLEET_C_MAINTLOG (Projection View + BDEF)            │
│   Metadata Extensions (UI Annotations)                  │
│   Value Help Views (ZFLEET_I_VEHSTATUS_VH, e.t.c)       │
├─────────────────────────────────────────────────────────┤
│                  BUSINESS LOGIC LAYER                   │
│   ZFLEET_BP_VEHICLE (Behavior Implementation Class)     │
│   — Early Numbering, Determinations, Validations,       │
│      Actions, Instance Feature Control                  │
├─────────────────────────────────────────────────────────┤
│                  INTERFACE (BO) LAYER                   │
│   ZFLEET_R_VEHICLE (Root Interface View + BDEF)         │
│   ZFLEET_R_AMAINTLOG (Child Interface View + BDEF)      │
├─────────────────────────────────────────────────────────┤
│                  DATABASE LAYER                         │
│   ZFLEET_AVHCLE (Transparent Table)                     │
│   ZFLEET_AMAINTLOG (Transparent Table)                  │
│   ZFLEET_DVHICLE (Draft Table)                          │
│   ZFLEET_DMAINTLOG (Draft Table)                        │
│   Domains → Data Elements → Table Fields                │
├─────────────────────────────────────────────────────────┤
│                  SERVICE LAYER                          │
│   ZFLEET_UI_VEHICLE (Service Definition)                │
│   ZFLEET_UI_VEHICLE_O4 (Service Binding — OData V4 UI)  │
└─────────────────────────────────────────────────────────┘
```
 
The business object (BO) has a **root-child composition**:
 
```
ZFLEET_R_VEHICLE  (Root BO — Vehicle)
    └──< ZFLEET_R_AMAINTLOG  (Child BO — Maintenance Log)
```
 
One vehicle can have zero or many maintenance logs. Locks, draft handling, and authorization flow from the root downward to the child automatically via the RAP framework.
 
---
 
## 3. Database Layer
 
### 3.1 Data Dictionary Objects
 
All business fields in the database tables are typed using **ABAP Dictionary data elements backed by custom domains**, rather than raw ABAP primitive types. This is the correct and recommended approach in SAP ABAP development because it provides:
 
- **Reusability** — a data element can be referenced by any number of table fields, structure fields, or function module parameters across the system
- **Field Labels** — short, medium, long, and heading labels defined once on the data element propagate automatically to CDS views and Fiori UI
- **F1 Documentation** — users pressing F1 on any field in the UI get the data element's documentation
- **Type Safety** — the domain enforces the technical data type and length at the dictionary layer, catching mismatches at activation time rather than at runtime
- **Maintainability** — changing a field's length or label in one place (the data element or domain) cascades to all consumers

#### Domains
 
| Domain | Type | Length | Purpose |
|---|---|---|---|
| `ZVEH_STATUS` | CHAR | 10 | Vehicle status codes (`INSERVICE`, `REPAIR`, `RETIRED`) |
| `ZLOG_STATUS` | CHAR | 10 | Log status codes (`OPEN`, `INPROGRESS`, `COMPLETED`) |
| `ZVEH_ID` | CHAR | 10 | Vehicle semantic display identifier |
| `ZVEH_TYPE` | CHAR | 20 | Vehicle type classification |
| `ZLOG_ID` | CHAR | 10 | Maintenance log semantic display identifier |
| `ZLOG_TYPE` | CHAR | 20 | Maintenance log type classification |
| `ZVEH_DESC` | CHAR | 100 | Vehicle description text |
| `ZLOG_DESC` | CHAR | 255 | Maintenance log description text |
| `ZVEH_PLATE` | CHAR | 20 | Vehicle license plate number |
| `ZVEH_DIST` | QUAN | 13,3 | Vehicle odometer mileage |
| `ZVEH_COST` | CURR | 16,2 | Maintenance cost amount |
 
> **Important:** Fixed values are defined on the status domains with corresponding descriptions. These values are then used to create dropdown domain value helps (see Section 5.3) for the respective actions in the fiori UI, to enable the end user to select the appropriate status.
 
#### Data Elements
 
Each domain is wrapped in a data element that carries the field labels:
 
| Data Element | Domain | Long Label |
|---|---|---|
| `ZVEH_STATUS` | `ZVEH_STATUS` | Vehicle Status |
| `ZLOG_STATUS` | `ZLOG_STATUS` | Maintenance Log Status |
| `ZVEH_ID` | `ZVEH_ID` | Vehicle ID |
| `ZVEH_TYPE` | `ZVEH_TYPE` | Vehicle Type |
| `ZLOG_ID` | `ZLOG_ID` | Log ID |
| `ZLOG_TYPE` | `ZLOG_TYPE` | Log Type |
| `ZVEH_DESC` | `ZVEH_DESC` | Vehicle Description |
| `ZLOG_DESC` | `ZLOG_DESC` | Log Description |
| `ZVEH_PLATE` | `ZVEH_PLATE` | License Plate |
| `ZVEH_DIST` | `ZVEH_DIST` | Vehicle Mileage |
| `ZVEH_COST` | `ZVEH_COST` | Maintenance Cost |
 
---
 
### 3.2 Database Tables
 
#### `ZFLEET_AVHCLE` — Fleet Vehicles
 
The root persistence table. Each row represents one vehicle or machine in the fleet.
 
| Field | Type / Data Element | Description |
|---|---|---|
| `CLIENT` | `abap.clnt` | SAP client (implicit key) |
| `VEHICLE_UUID` | `sysuuid_x16` | Technical UUID primary key — set by early numbering |
| `VEHICLE_ID` | `ZVEH_ID` | Human-readable semantic ID — set by determination |
| `DESCRIPTION` | `ZVEH_DESC` | Full vehicle description |
| `VEHICLE_TYPE` | `ZVEH_TYPE` | Classification: Van, Truck, Bus, SUV, Pickup, Machine |
| `LICENSE_PLATE` | `ZVEH_PLATE` | Registration plate number |
| `STATUS` | `ZVEH_STATUS` | Current lifecycle status |
| `STATUS_CRITICALITY` | `abap.char(1)` | Fiori criticality integer for colour coding (0–3) |
| `ACQUISITION_DATE` | `ZVEH_DATE` | Date the vehicle was acquired |
| `MILEAGE` | `ZVEH_DIST` | Current odometer reading |
| `RESPONSIBLE_PERSON` | `ZVEH_PERSON` | User ID of the assigned responsible person |
 
#### `ZFLEET_AMAINTLOG` — Vehicle Maintenance Logs
 
The child persistence table. Each row is one maintenance event linked to a parent vehicle.
 
| Field | Type / Data Element | Description |
|---|---|---|
| `CLIENT` | `abap.clnt` | SAP client |
| `LOG_UUID` | `sysuuid_x16` | Technical UUID primary key — set by early numbering |
| `VEHICLE_UUID` | `sysuuid_x16` | Foreign key to parent `ZFLEET_AVHCLE` |
| `LOG_ID` | `ZLOG_ID` | Human-readable semantic ID — set by determination |
| `LOG_TYPE` | `ZLOG_TYPE` | Type of event: REPAIR, SERVICE, INSPECTION |
| `DESCRIPTION` | `ZLOG_DESC` | Detailed description of the maintenance work |
| `STATUS` | `ZLOG_STATUS` | Current log status: OPEN, INPROGRESS, COMPLETED |
| `ASSIGNED_TECHNICIAN` | `ZLOG_TECH` | User ID of the assigned technician |
| `START_DATE` | `ZLOG_START_DATE` | Date work commenced |
| `END_DATE` | `ZLOG_END_DATE` | Date work was completed |
| `COST` | `ZVEH_COST` | Total cost of the maintenance event |

The necessary admin fields for concurrency control are appended to the end of the tables by an include structure `zfleet_s_admin_fields`.

#### Draft Tables
 
| Table | Backs |
|---|---|
| `ZFLEET_DVHICLE` | Draft instances of `ZFLEET_AVHCLE` |
| `ZFLEET_DMAINTLOG` | Draft instances of `ZFLEET_AMAINTLOG` |
 
Both draft tables are generated by the ADT RAP generator from the BDEF. They mirror the structure of their corresponding active tables and include additional RAP draft administration fields (`DRAFTENTITYCREATIONDATETIME`, `DRAFTENTITYLASTCHANGEDATETIME`, `DRAFTINPROCESSBYUSER`, etc.) managed entirely by the framework.
 
---
 
## 4. Numbering Strategy
 
The project uses an **unmanaged early numbering scenario** that separates the technical key from the human-readable identifier:
 
### Technical UUID — Unmanaged Early Numbering
 
Both `VehicleUUID` and `LogUUID` are implemented with the `early_numbering` method in the behaviour pool. Since `Logs` is a child of `Vehicle`, the `LogUUID` is implemented by the method `earlynumbering_cba_Logs`. The application provides a custom implementation via the `early numbering action create for numbering` hook. This fires **before** the create operation reaches the database.
 
### Semantic ID — Unmanaged Early Numbering via determinations.
 
`Vehicle_ID` and `Log_ID` are implemented using determinations `setVehicleID` and `setLogID` respectively in the behaviour pool. The determinations make use of buffered number range objects to determine the next free/available number to be assigned to a newly created instance at runtime. 
The implementation calls `cl_numberrange_runtime=>number_get` against the two dedicated number range objects.
 
---
 
## 5. CDS View Layer
 
### 5.1 Interface Views
 
Interface views form the **Business Object (BO) layer** and define the data model that the behavior definition and implementation operate against. They are not exposed directly to the UI.
 
#### `ZFLEET_R_VEHICLE` — Root Interface View
 
- Selects from `ZFLEET_AVHCLE`
- Declared as `define root view entity`
- Contains a **composition** to `ZFLEET_R_AMAINTLOG` via `_Logs`
- Contains an **association** to value help `ZFLEET_I_VEHSTATUS_VH` as `_StatusVH` to expose `StatusText` in the projection view.
- Is the anchor point for the root BDEF

#### `ZFLEET_R_AMAINTLOG` — Child Interface View
 
- Selects from `ZFLEET_AMAINTLOG`
- Declared as `define view entity` (not root)
- Contains an **association to parent** `ZFLEET_R_VEHICLE` via `_Vehicle`
- Is locked and authorized through its parent (root) entity
---
 
### 5.2 Projection Views
 
Projection views form the **consumption layer** and shape the BO for a specific UI use case. They are what the service definition exposes.
 
#### `ZFLEET_C_VEHICLE` — Vehicle Projection View
 
- Declared with `provider contract transactional_query`
- Contains an **association field** `_StatusVH.StatusText` to derive `StatusText` from the associated value help `ZFLEET_I_VEHSTATUS_VH`.
- Annotated with `@ObjectModel.text.element: ['StatusText']` so Fiori renders the descriptive text alongside the code.
- Declares `@Consumption.valueHelpDefinition` on `Status` pointing to `ZFLEET_I_VEHSTATUS_VH`.
- Redirects the `_Logs` composition to the child projection `Zfleet_C_MaintLog`.

#### `ZFLEET_C_MAINTLOG` — Maintenance Log Projection View
 
- Projects from `ZFLEET_A_AMAINTLOG`
- Redirects the `_Vehicle` association back to the parent projection `ZFLEET_C_VEHICLE`
- Annotated with `@Consumption.valueHelpDefinition` on `Status` pointing to `ZFLEET_I_LOGSTATUS_VH`
---
 
### 5.3 Value Help Views
 
Because the status domains carry fixed values (see Section 3.1), domain value helps are provided via standard CDS views fetching the fixed values and their corresponding description texts. 
 
Both views use `select from DDCDS_CUSTOMER_DOMAIN_VALUE_T()` as their data source. The data source takes in a parameter `p_domain_name` that accepts the respective domain as its value.
 
#### `ZFLEET_I_VEHSTATUS_VH`
 
| Fixed Value | Description |
|---|---|
| `INSERVICE` | In Service |
| `REPAIR` | Under Repair |
| `RETIRED` | Retired |
 
#### `ZFLEET_I_LOGSTATUS_VH`
 
| Fixed Value | Description |
|---|---|
| `OPEN` | Open |
| `INPROGRESS` | In Progress |
| `COMPLETED` | Completed |

#### `ZFLEET_I_VEHICLE_VH`
An additional simple value help `ZFLEET_I_VEHICLE_VH` is defined for use as a searchable value help in the filter bar of the fiori UI.

---
 
## 6. Metadata Extensions
 
UI annotations are kept **out of the projection views** and managed in separate Metadata Extension (MDE) objects. This cleanly separates data modelling from UI concerns and allows the UI to be adjusted without touching or re-activating the CDS views.
 
### `ZFLEET_C_VEHICLE` Metadata Extension
 
Configures the List Report and Object Page for vehicles:
 
- **List Report columns:** Vehicle ID, Description, Vehicle Type, License Plate, Status (with criticality-driven colour), Mileage
- **Selection fields:** Vehicle ID, Status
- **Object Page facets:**
  - A `DATAPOINT_REFERENCE` header facet showing the current status with criticality colour
  - A General Information identification facet with all vehicle fields
  - A `LINEITEM_REFERENCE` facet rendering the `_Logs` child table inline on the object page
- **Action buttons** wired to the three state machine actions: Send to Repair, Return to Service, Retire Vehicle — rendered both on the list report toolbar and the object page header

### `ZFLEET_C_MAINTLOG` Metadata Extension
 
Configures the embedded maintenance log table and the log detail object page:
 
- **Table columns:** Log ID, Log Type, Description, Status, Cost
- **Selection fields:** Status
- **Object Page facets:** Single identification facet with all log fields
---
 
## 7. Behavior Definition Layer
 
### 7.1 Interface BDEF — `ZFLEET_BP_VEHICLE`
 
The interface BDEF is declared `managed` with `with draft` and `strict(2)`. It defines the complete capability set of the business object.
 
**Vehicle entity capabilities:**
 
| Declaration | Purpose |
|---|---|
| `action ( features : instance ) sendToRepair` | State machine transition |
| `action ( features : instance ) returnToService` | State machine transition |
| `action ( features : instance ) retireVehicle` | State machine transition |
| `determination setVehicleID on modify {create;}`| Set semantic ID on instance creation |
| `determination setInitialStatus on modify { create; }` | Default status on new vehicle |
| `determination setStatusCriticality on modify { field Status; }` | UI colour code on status change |
| `validation validateRequiredFields on save` | Mandatory field check |
| `validation validateRetireConditions on save` | Block retirement if open logs exist |
| `validation validateStatusTransition on save` | Enforce legal status transitions |
 
**Logs entity capabilities:**
 
| Declaration | Purpose |
|---|---|
| `determination setLogID on modify {create;}` | Set semantic ID on instance creation |
| `determination setDefaultLogStatus on modify { create; }` | Default status OPEN on new log |
| `validation validateLogDates on save` | End date must not precede start date |
| `validation validateCompletedLog on save` | Completed log must have end date and cost |
 
---
 
### 7.2 Projection BDEF — `Zfleet_C_Vehicle`
 
Declared `projection` with `with draft`. Simply re-exposes the capabilities defined in the interface BDEF that are relevant for this UI scenario. Uses `use create`, `use update`, `use delete`, `use action`, and `use draft action` statements. The projection BDEF does not add any new logic.
 
---
 
## 8. Behavior Implementation
 
All behavior implementation resides in class `ZFLEET_BP_VEHICLE`. The class definition is minimal (abstract, final, for behavior of `ZFLEET_R_VEHICLE`); the actual logic lives in **local handler classes** inside the CCIMP include:
 
- `lhc_zfleet_r_vehicle` — handles all Vehicle entity events
- `lhc_logs` — handles all Log entity events
---
 
### 8.1 Early Numbering
 
#### `LHC_VEHICLE~earlynumbering_create`
 
**Trigger:** Every `CREATE` operation on the Vehicle entity, including draft creates.
 
**Purpose:** Assigns the technical `VehicleUUID` before the record is written to the database.

#### `LHC_LOGS~earlynumbering_create`
 
**Trigger:** Every `CREATE` operation on the Logs entity, including draft creates.
 
**Purpose:** Assigns the technical `LogUUID`.
 
---
 
### 8.2 Determinations
 
Determinations are server-side logic blocks that fire automatically when specific conditions are met during a modify operation. They cannot be triggered manually from the UI.

#### `setVehicleID` — Vehicle

**Trigger:** `on modify { create; }` — fires once when a new Vehicle instance is created.

**Purpose:** Sets a semantic id number to the newly created vehicle.

**Implementation:** Uses a number range to determine the ID of the instance.
 
#### `setInitialStatus` — Vehicle
 
**Trigger:** `on modify { create; }` — fires once when a new Vehicle instance is created.
 
**Purpose:** Sets the default `Status` field to `INSERVICE` on every new vehicle so the record always has a defined state from the moment of creation. Without this, a newly created vehicle would have a blank status until the user manually selected one.
 
**Implementation:** Reads the new instances in local mode, checks for a blank status, and writes `INSERVICE` back via a local modify.
 
---
 
#### `setStatusCriticality` — Vehicle
 
**Trigger:** `on modify { field Status; }` — fires whenever the `Status` field changes on any Vehicle instance.
 
**Purpose:** Maintains the `StatusCriticality` integer field, which drives the colour-coded status indicator in the Fiori UI:
 
| Status | Criticality Value | Fiori Colour |
|---|---|---|
| `INSERVICE` | `3` | Green |
| `REPAIR` | `2` | Orange / Warning |
| `RETIRED` | `1` | Red / Error |
 
This avoids embedding colour logic in the frontend and keeps it server-side where it is consistent across all consumers.
 
---

#### `setLogID` — Logs

**Trigger:** `on modify { create; }` — fires once when a new vehicle log instance is created.

**Purpose:** Sets a semantic id number to the newly created log.

**Implementation:** Uses a number range to determine the ID of the instance.
 
#### `setDefaultLogStatus` — Logs
 
**Trigger:** `on modify { create; }` — fires when a new MaintLog instance is created.
 
**Purpose:** Defaults the log `Status` to `OPEN` so every new log starts in a defined, actionable state. Mirrors the pattern of `setInitialStatus` for the child entity.
 
---
 
### 8.3 Validations
 
Validations enforce business rules at save time (including draft activation). They run as part of the `Prepare` draft determine action and on final activation. If a validation fails, it appends to both `reported` (user-facing message) and `failed` (blocks the save), and the field that caused the failure is flagged so the UI can highlight it.
 
#### `validateRequiredFields` — Vehicle
 
**Trigger:** `on save { create; update; }`
 
**Purpose:** Ensures that `VehicleType`, `AcquisitionDate`, `Description` and `LicensePlate` are not blank before the record can be saved. These are the minimum fields required for a vehicle to be meaningful in the fleet list.
 
**Behaviour on failure:** Error message returned, save blocked. The offending field is highlighted in the Fiori form via `%element-<FieldName> = if_abap_behv=>mk-on`.
 
---
 
#### `validateStatusTransition` — Vehicle
 
**Trigger:** `on save { field Status; }`
 
**Purpose:** Enforces the legal state machine transition matrix. A user cannot jump to an arbitrary status — only allowed transitions proceed. The whitelist is:
 
| From | Allowed Transitions |
|---|---|
| `INSERVICE` | `INSERVICE`, `REPAIR`, `RETIRED` |
| `REPAIR` | `REPAIR`, `INSERVICE`, `RETIRED` |
| `RETIRED` | `RETIRED` only — no exit from Retired |
 
**Implementation:** Reads the current persisted status from the database for comparison, then checks the proposed new status against the whitelist using a `SWITCH` expression. New records (no persisted row) are skipped.
 
**Behaviour on failure:** Error message with transition details (e.g. `Invalid transition: RETIRED → INSERVICE`), save blocked.
 
---
 
#### `validateRetireConditions` — Vehicle
 
**Trigger:** `on save { field Status; }`
 
**Purpose:** Prevents a vehicle from being retired if it has any maintenance logs in status `OPEN` or `INPROGRESS`. This is the core business rule that protects data integrity — you cannot write off an asset that still has unresolved maintenance tasks.
 
**Implementation:**
1. Filters to only vehicles where the proposed `Status` is `RETIRED`
2. Reads the child `_Logs` association for each candidate
3. Counts logs where `Status = 'OPEN' OR Status = 'INPROGRESS'`
4. If count > 0, blocks the save with a message that states the number of blocking logs
**Behaviour on failure:** Error message (e.g. `Cannot retire: 2 active maintenance log(s) exist`), save blocked.
 
---
 
#### `validateLogDates` — Logs
 
**Trigger:** `on save {create; field StartDate; field EndDate; }`
 
**Purpose:** Ensures the `EndDate` of a maintenance log is not set to a date before the `StartDate`. Prevents nonsensical date ranges and downstream reporting errors.
 
**Behaviour on failure:** Error on `EndDate` field, save blocked.
 
---
 
#### `validateCompletedLog` — Logs
 
**Trigger:** `on save { field Status; }`
 
**Purpose:** When a log is being set to `COMPLETED`, enforces that:
1. `EndDate` is populated (mandatory — a completed job must have a completion date)
2. `Cost` is not zero (warning — flags likely missing cost entry without blocking)
**Behaviour on failure:** Error on `EndDate` blocks the save; Warning on `Cost` allows save but surfaces an advisory message to the user.
 
---
 
### 8.4 Actions
 
Actions are explicitly triggered by the user from the UI (via buttons) or programmatically. All three vehicle actions are declared `( features : instance )` meaning their enabled/disabled state is computed per-record by the instance feature control method.
 
Each action returns `result [1] $self` — after execution, the updated vehicle instance is returned to the UI so the status change is immediately visible without a separate refresh.
 
#### `sendToRepair` — Vehicle
 
**Purpose:** Transitions a vehicle from `INSERVICE` to `REPAIR` status, representing the moment a vehicle is taken out of active fleet use and handed to the workshop.
 
**Guard:** Only vehicles in `INSERVICE` status can be sent to repair. Any other status causes an error message and the action aborts for that instance.
 
**Side effect — automatic log creation:** When the action executes successfully, it automatically creates a new `MaintLog` child record with:
- `LogType = 'REPAIR'`
- `Status = 'OPEN'`
- `StartDate` set to the current system date
- `Description` stamped with the date for traceability
This ensures there is always an audit trail entry whenever a vehicle enters repair — the log cannot be forgotten.
 
---
 
#### `returnToService` — Vehicle
 
**Purpose:** Transitions a vehicle from `REPAIR` back to `INSERVICE`, representing the moment the workshop releases the vehicle back to active fleet use.
 
**Guard:** Only vehicles in `REPAIR` status can be returned to service.
 
**Note:** This action does not automatically close any open maintenance logs. The technician is expected to close or complete the relevant log entries separately, reflecting real-world practice where the repair record is signed off independently of the vehicle's operational status.
 
---
 
#### `retireVehicle` — Vehicle
 
**Purpose:** Permanently transitions a vehicle to `RETIRED` status. Once retired, the vehicle is read-only and cannot be returned to any other status.
 
**Guard:** Vehicles already in `RETIRED` status produce a warning. The `validateRetireConditions` validation (Section 8.3) is the primary defence against retiring a vehicle with open logs — if that validation fires, it blocks activation before this action's status change can be committed.
 
---
 
### 8.5 Instance Feature Control
 
Instance feature control dynamically computes the enabled/disabled state of actions and the editable/read-only state of fields **per record instance** based on the current data state. This runs every time the UI renders an instance.
 
#### Vehicle Feature Control
 
| Condition | Effect |
|---|---|
| `Status = 'INSERVICE'` | `sendToRepair` enabled; `returnToService` disabled |
| `Status = 'REPAIR'` | `returnToService` enabled; `sendToRepair` disabled |
| `Status = 'RETIRED'` | Action `Edit` is disabled; all fields set to read-only |
| Any status | `retireVehicle` enabled unless already `RETIRED` |
 
#### Logs Feature Control
 
| Condition | Effect |
|---|---|
| `Status = 'COMPLETED'` | Feature `update` is disabled, all fields set to read-only |
| `Status = 'OPEN'` | Feature `delete` is enabled, otherwise `delete` is disabled |
 
This prevents modification of completed maintenance records, preserving their integrity as a historical audit trail.
 
---
 
## 9. Draft Handling
 
The application is fully **draft-enabled** for both the Vehicle root entity and the MaintLog child entity. Draft support is declared in both the interface and projection BDEFs with `with draft`.
 
### What Draft Enables
 
- Draft records are private to the creating user until activated
- The framework provides four standard draft actions:
  - **Edit** — creates a draft copy of an active record for editing
  - **Activate** — validates and commits the draft to the active database table
  - **Discard** — deletes the draft without affecting the active record
  - **Resume** — reopens an existing draft for continued editing
- **Prepare** — a `draft determine action` that runs all bound validations before the user attempts to activate, giving early feedback without committing

---
 
## 10. Service Definition and Binding
 
### Service Definition — `ZFLEET_UI_VEHICLE`
 
Exposes the two projection views as named OData entity sets:
 
```
expose Zfleet_C_Vehicle  as Vehicle;
expose Zfleet_C_MaintLog as Logs;
```
 
### Service Binding — `ZFLEET_UI_VEHICLE_O4`
 
- **Binding type:** OData V4 — UI
- **Protocol:** OData V4 (required for Fiori Elements draft support)
- Published via the **Publish** action in ADT
- The **Preview** button in ADT launches the Fiori Elements List Report application directly in the browser for immediate testing without deploying to a Fiori launchpad
---
 
---
 
## 11. State Machine Reference
 
```
                    ┌─────────────────┐
       [Create]     │                 │
      ─────────────►│   IN SERVICE    │◄──────────────┐
                    │   (INSERVICE)   │               │
                    └────────┬────────┘               │
                             │                        │
                    sendToRepair action       returnToService action
                             │                        │
                             ▼                        │
                    ┌─────────────────┐               │
                    │                 │               │
                    │  UNDER REPAIR   │───────────────┘
                    │   (REPAIR)      │
                    └────────┬────────┘
                             │
                    retireVehicle action
                    (blocked if open logs exist)
                             │
                             ▼
                    ┌─────────────────┐
                    │                 │
                    │    RETIRED      │  ← Terminal state. No exit.
                    │   (RETIRED)     │     All fields read-only.
                    │                 │
                    └─────────────────┘
```
 
### Transition Rules Summary
 
| From → To | Mechanism | Blocking Condition |
|---|---|---|
| *(new)* → `INSERVICE` | `setInitialStatus` determination | None |
| `INSERVICE` → `REPAIR` | `sendToRepair` action | None; auto-creates repair log |
| `REPAIR` → `INSERVICE` | `returnToService` action | None |
| `INSERVICE` → `RETIRED` | `retireVehicle` action | Open or in-progress maintenance logs |
| `REPAIR` → `RETIRED` | `retireVehicle` action | Open or in-progress maintenance logs |
| `RETIRED` → *(any)* | **Not permitted** | `validateStatusTransition` blocks |
