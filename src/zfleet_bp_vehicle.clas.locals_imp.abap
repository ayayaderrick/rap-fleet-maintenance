CLASS lhc_logs DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS setLogID FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Logs~setLogID.
    METHODS validateLogDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR Logs~validateLogDates.
    METHODS validateCompletedLog FOR VALIDATE ON SAVE
      IMPORTING keys FOR Logs~validateCompletedLog.
    METHODS setDefaultLogStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Logs~setDefaultLogStatus.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Logs RESULT result.

ENDCLASS.

CLASS lhc_logs IMPLEMENTATION.

  METHOD setLogID.

    DATA:
      log_id_max       TYPE zlog_id,
      " change to abap_false if you get the ABAP Runtime error 'BEHAVIOR_ILLEGAL_STATEMENT'
      use_number_range TYPE abap_bool VALUE abap_false.

    " Read the newly created child logs via their keys
    READ ENTITIES OF zfleet_r_vehicle IN LOCAL MODE
    ENTITY Logs
    FIELDS ( LogID VehicleUUID ) WITH CORRESPONDING #( keys )
    RESULT DATA(lt_logs).

    " Filter out logs that already processed an ID
    DATA(lt_logs_wo_id) = lt_logs.
    DELETE lt_logs_wo_id WHERE LogID IS NOT INITIAL.

    " Determine the starting ID threshold
    IF use_number_range = abap_true.
      "Get numbers
      TRY.
          cl_numberrange_runtime=>number_get(
              EXPORTING
              nr_range_nr = '01'
              object = 'ZFLT_LOG'
              quantity = CONV #( lines( lt_logs_wo_id ) )
              IMPORTING
              number = DATA(number_range_key)
              returncode        = DATA(number_range_return_code)
              returned_quantity = DATA(number_range_returned_quantity)
           ).
        CATCH cx_number_ranges INTO DATA(lx_number_ranges).
          " Log error messages back to the Fiori UI
          LOOP AT lt_logs_wo_id INTO DATA(ls_err_log).
            APPEND VALUE #(
                loguuid = ls_err_log-LogUUID
                %is_draft = ls_err_log-%is_draft
                %msg = lx_number_ranges
             ) TO reported-logs.
          ENDLOOP.
          RETURN.
      ENDTRY.

      "determine the first free Vehicle ID from the number range
      log_id_max = number_range_key - number_range_returned_quantity.

    ELSE.
      " Fallback: Scan active and draft child tables for maximum existing ID
      "determine the first free Log ID without number range
      "Get max Log ID from active table
      SELECT SINGLE FROM zfleet_amaintlog FIELDS MAX( log_id ) AS LogID INTO @log_id_max.
      "Get max Log ID from draft table
      SELECT SINGLE FROM zfleet_dmaintlog FIELDS MAX( logid ) INTO @DATA(max_logid_draft).
      IF max_logid_draft > log_id_max.
        log_id_max = max_logid_draft.
      ENDIF.
    ENDIF.

    " Prepare the update sequence using child entity structures
    DATA lt_log_update TYPE TABLE FOR UPDATE zfleet_r_amaintlog.

    LOOP AT lt_logs_wo_id INTO DATA(ls_log).
      log_id_max += 1.

      APPEND VALUE #(
          loguuid = ls_log-LogUUID
          %is_draft = ls_log-%is_draft
          logid = log_id_max
          %control-logid = if_abap_behv=>mk-on
       ) TO lt_log_update.
    ENDLOOP.

    " Update the child sub-component framework buffer
    MODIFY ENTITIES OF zfleet_r_vehicle IN LOCAL MODE
    ENTITY Logs
    UPDATE FIELDS ( LogID ) WITH lt_log_update.

  ENDMETHOD.

  METHOD validateLogDates.

    READ ENTITIES OF zfleet_r_vehicle IN LOCAL MODE
    ENTITY Logs
    FIELDS ( StartDate EndDate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(logs).

    LOOP AT logs INTO DATA(log).
      APPEND VALUE #(
            %tky        = log-%tky
            %state_area = 'VALIDATE_DATES'
        ) TO reported-logs.
      IF log-StartDate IS NOT INITIAL AND log-EndDate IS NOT INITIAL AND log-EndDate < log-StartDate.
        APPEND VALUE #(
            %tky = log-%tky
            %state_area = 'VALIDATE_DATES'
            %path = VALUE #( vehicle-%is_draft = log-%is_draft
                             vehicle-vehicleuuid = log-VehicleUUID )
            %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-error
                text = 'End date cannot be before Start date.'
             )
            %element-EndDate = if_abap_behv=>mk-on
         ) TO reported-logs.
        APPEND VALUE #( %tky = log-%tky ) TO failed-logs.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateCompletedLog.

    " A completed log must have an end date and cost
    READ ENTITIES OF zfleet_r_vehicle IN LOCAL MODE
    ENTITY Logs
    FIELDS ( Status EndDate Cost )
    WITH CORRESPONDING #( keys )
    RESULT DATA(logs).

    LOOP AT logs INTO DATA(log).

      " Critical for Draft: Clear the state area message container before re-validating
      APPEND VALUE #(
          %tky        = log-%tky
          %state_area = 'VALIDATE_COMPLETE'
      ) TO reported-logs.

      CHECK log-Status = 'COMPLETED'.

      IF log-EndDate IS INITIAL.
        APPEND VALUE #(
            %tky = log-%tky
            %state_area = 'VALIDATE_COMPLETE'
            %path = VALUE #( vehicle-%is_draft = log-%is_draft
                             vehicle-vehicleuuid = log-VehicleUUID )
            %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-error
                text = 'End Date is required when completing a log.'
         )
        %element-EndDate = if_abap_behv=>mk-on
     ) TO reported-logs.
        APPEND VALUE #( %tky = log-%tky ) TO failed-logs.
      ENDIF.

      IF log-Cost IS INITIAL OR log-Cost = 0.
        APPEND VALUE #(
            %tky = log-%tky
            %state_area = 'VALIDATE_COMPLETE'
            %path = VALUE #( vehicle-%is_draft = log-%is_draft
                             vehicle-vehicleuuid = log-VehicleUUID )
            %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-error
                text = 'Cost is required when completing a log.'
         )
        %element-Cost = if_abap_behv=>mk-on
     ) TO reported-logs.
        APPEND VALUE #( %tky = log-%tky ) TO failed-logs.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD setDefaultLogStatus.

    READ ENTITIES OF zfleet_r_vehicle IN LOCAL MODE
    ENTITY Logs
    FIELDS ( Status )
    WITH CORRESPONDING #( keys )
    RESULT DATA(logs).

    " If status is already set, do nothing
    DELETE logs WHERE Status IS NOT INITIAL.
    CHECK logs IS NOT INITIAL.

    " Else set the status to OPEN
    MODIFY ENTITIES OF zfleet_r_vehicle IN LOCAL MODE
    ENTITY Logs
    UPDATE FIELDS ( Status )
    WITH VALUE #( FOR log IN logs ( %tky = log-%tky Status = 'OPEN' ) )
    REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).

  ENDMETHOD.

  METHOD get_instance_features.

    READ ENTITIES OF zfleet_r_vehicle IN LOCAL MODE
    ENTITY Logs
    FIELDS ( LogID Status )
    WITH CORRESPONDING #( keys )
    RESULT DATA(logs)
    FAILED failed.

    result = value #( for log in logs (
        %tky = log-%tky
        %features-%update = COND #( WHEN log-Status = 'COMPLETED' THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled )
        %features-%delete = COND #( WHEN log-Status = 'OPEN' THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
     ) ).

  ENDMETHOD.

ENDCLASS.

CLASS lhc_zfleet_r_vehicle DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING
        REQUEST requested_authorizations FOR Vehicle
        RESULT result,
      earlynumbering_create FOR NUMBERING
        IMPORTING entities FOR CREATE Vehicle,
      setVehicleID FOR DETERMINE ON MODIFY
        IMPORTING keys FOR Vehicle~setVehicleID,
      earlynumbering_cba_Logs FOR NUMBERING
        IMPORTING entities FOR CREATE Vehicle\_Logs,
      setStatusCriticality FOR DETERMINE ON MODIFY
        IMPORTING keys FOR Vehicle~setStatusCriticality,
      retireVehicle FOR MODIFY
        IMPORTING keys FOR ACTION Vehicle~retireVehicle RESULT result.

    METHODS returnToService FOR MODIFY
      IMPORTING keys FOR ACTION Vehicle~returnToService RESULT result.

    METHODS sendToRepair FOR MODIFY
      IMPORTING keys FOR ACTION Vehicle~sendToRepair RESULT result.
    METHODS validateRetireConditions FOR VALIDATE ON SAVE
      IMPORTING keys FOR Vehicle~validateRetireConditions.

    METHODS validateStatusTransition FOR VALIDATE ON SAVE
      IMPORTING keys FOR Vehicle~validateStatusTransition.
    METHODS validateRequiredFields FOR VALIDATE ON SAVE
      IMPORTING keys FOR Vehicle~validateRequiredFields.
    METHODS setInitialStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Vehicle~setInitialStatus.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Vehicle RESULT result.
ENDCLASS.

CLASS lhc_zfleet_r_vehicle IMPLEMENTATION.
  METHOD get_global_authorizations.
  ENDMETHOD.
  METHOD earlynumbering_create.

    DATA entity TYPE STRUCTURE FOR CREATE zfleet_r_vehicle.

    "Ensure Vehicle UUID is not set yet - must be checked when BO is draft-enabled
    LOOP AT entities INTO entity WHERE VehicleUUID IS NOT INITIAL.
      APPEND CORRESPONDING #( entity ) TO mapped-vehicle.
    ENDLOOP.

    DATA(entities_wo_vehicleuuid) = entities.
    "Remove the entries with an existing Travel ID
    DELETE entities_wo_vehicleuuid WHERE VehicleUUID IS NOT INITIAL.

    " Generate UUIDs for new instances
    LOOP AT entities_wo_vehicleuuid INTO entity.
      DATA(lv_uuid) = xco_cp=>uuid(  )->value.
      APPEND VALUE #(
          %cid = entity-%cid
          %is_draft = entity-%is_draft
          vehicleuuid = lv_uuid
       ) TO mapped-vehicle.
    ENDLOOP.


  ENDMETHOD.

  METHOD setVehicleID.

    DATA:
      vehicle_id_max   TYPE zveh_id,
      " change to abap_false if you get the ABAP Runtime error 'BEHAVIOR_ILLEGAL_STATEMENT'
      use_number_range TYPE abap_bool VALUE abap_false.

    " Read the newly created instances
    READ ENTITIES OF zfleet_r_vehicle IN LOCAL MODE
    ENTITY Vehicle
    FIELDS ( VehicleID ) WITH CORRESPONDING #( keys )
    RESULT DATA(vehicles).

    " Filter out any records that already have a VehicleID assigned
    DATA(vehicles_wo_id) = vehicles.
    DELETE vehicles_wo_id WHERE VehicleID IS NOT INITIAL.

    " Determine the starting ID threshold
    IF use_number_range = abap_true.
      "Get numbers
      TRY.
          cl_numberrange_runtime=>number_get(
              EXPORTING
              nr_range_nr = '01'
              object = 'ZFLT_MAINT'
              quantity = CONV #( lines( vehicles_wo_id ) )
              IMPORTING
              number = DATA(number_range_key)
              returncode        = DATA(number_range_return_code)
              returned_quantity = DATA(number_range_returned_quantity)
           ).
        CATCH cx_number_ranges INTO DATA(lx_number_ranges).
          " Log error messages back to the Fiori UI
          LOOP AT vehicles_wo_id INTO DATA(ls_err_veh).
            APPEND VALUE #(
                vehicleuuid = ls_err_veh-VehicleUUID
                %is_draft = ls_err_veh-%is_draft
                %msg = lx_number_ranges
             ) TO reported-vehicle.
          ENDLOOP.
          RETURN.
      ENDTRY.

      "determine the first free Vehicle ID from the number range
      vehicle_id_max = number_range_key - number_range_returned_quantity.
    ELSE.
      "determine the first free Vehicle ID without number range
      "Get max Vehicle ID from active table
      SELECT SINGLE FROM zfleet_avhcle FIELDS MAX( vehicle_id ) AS VehicleID INTO @vehicle_id_max.
      "Get max Vehicle ID from draft table
      SELECT SINGLE FROM zfleet_dvhicle FIELDS MAX( vehicleid ) INTO @DATA(max_vehicleid_draft).
      IF max_vehicleid_draft > vehicle_id_max.
        vehicle_id_max = max_vehicleid_draft.
      ENDIF.

    ENDIF.

    " Prepare the update sequence using EML
    DATA lt_update TYPE TABLE FOR UPDATE zfleet_r_vehicle.

    LOOP AT vehicles_wo_id INTO DATA(ls_vehicle).
      vehicle_id_max += 1.
      APPEND VALUE #(
          vehicleuuid = ls_vehicle-VehicleUUID
          %is_draft = ls_vehicle-%is_draft
          vehicleid = vehicle_id_max
          %control-vehicleid = if_abap_behv=>mk-on
       ) TO lt_update.
    ENDLOOP.

    " Update the framework's transactional buffer
    MODIFY ENTITIES OF zfleet_r_vehicle IN LOCAL MODE
    ENTITY Vehicle
    UPDATE FIELDS ( VehicleID ) WITH lt_update.

  ENDMETHOD.

  METHOD earlynumbering_cba_Logs.

    LOOP AT entities INTO DATA(ls_parent_entity).
      LOOP AT ls_parent_entity-%target INTO DATA(ls_child_log)
        WHERE LogUUID IS NOT INITIAL.

        " If UUID is somehow already set, pass it straight through
        APPEND VALUE #(
            %cid = ls_child_log-%cid
            %is_draft = ls_child_log-%is_draft
            LogUUID   = ls_child_log-LogUUID
         ) TO mapped-logs.
      ENDLOOP.
      DATA(lt_children_wo_uuid) = ls_parent_entity-%target.
      DELETE lt_children_wo_uuid WHERE LogUUID IS NOT INITIAL.

    ENDLOOP.

    LOOP AT lt_children_wo_uuid INTO ls_child_log.
      TRY.
          DATA(lv_child_uuid) = xco_cp=>uuid(  )->value.
        CATCH cx_uuid_error.
          APPEND VALUE #(
              %cid = ls_child_log-%cid
              %is_draft = ls_child_log-%is_draft
           ) TO failed-logs.
          CONTINUE.
      ENDTRY.
      " Map the child target instance to its newly generated UUID key
      APPEND VALUE #(
          %cid = ls_child_log-%cid
          %is_draft = ls_child_log-%is_draft
          loguuid = lv_child_uuid
       ) TO mapped-logs.
    ENDLOOP.

  ENDMETHOD.

  METHOD setStatusCriticality.

    " Map status to Fiori criticality integer for colour-coding
    " 0=None, 1=Error(Red), 2=Warning(Orange), 3=Success(Green)
    READ ENTITIES OF zfleet_r_vehicle IN LOCAL MODE
    ENTITY Vehicle
    FIELDS ( Status ) WITH CORRESPONDING #( keys )
    RESULT DATA(vehicles).

    DATA lt_updates TYPE TABLE FOR UPDATE zfleet_r_vehicle\\Vehicle.

    LOOP AT vehicles INTO DATA(vehicle).
      DATA(lv_criticality) = SWITCH #( vehicle-Status
          WHEN 'INSERVICE' THEN '3'
          WHEN 'REPAIR' THEN '2'
          WHEN 'RETIRED' THEN '1'
          ELSE '0'
       ).

      APPEND VALUE #(
         %tky = vehicle-%tky
         statuscriticality = lv_criticality
       ) TO lt_updates.
    ENDLOOP.

    MODIFY ENTITIES OF zfleet_r_vehicle IN LOCAL MODE
    ENTITY Vehicle
    UPDATE FIELDS ( StatusCriticality ) WITH lt_updates
    REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).

  ENDMETHOD.

  METHOD retireVehicle.

    " Note: validateRetireConditions blocks this if open logs exist.
    " The action itself just drives the status change.

    READ ENTITIES OF zfleet_r_vehicle IN LOCAL MODE
    ENTITY Vehicle
    FIELDS ( Status ) WITH CORRESPONDING #( keys )
    RESULT DATA(vehicles).

    DATA lt_updates TYPE TABLE FOR UPDATE zfleet_r_vehicle\\Vehicle.

    LOOP AT vehicles INTO DATA(vehicle).
      IF vehicle-Status = 'RETIRED'.
        APPEND VALUE #(
            %tky = vehicle-%tky
            %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-error
                text = 'Vehicle is already retired.'
             )
         ) TO reported-vehicle.
        APPEND VALUE #( %tky = vehicle-%tky ) TO failed-vehicle.
        CONTINUE.
      ENDIF.

      " Update vehicle status
      APPEND VALUE #(
          %tky = vehicle-%tky
          status = 'RETIRED'
       ) TO lt_updates.

    ENDLOOP.

    IF lt_updates IS NOT INITIAL.
      MODIFY ENTITIES OF zfleet_r_vehicle IN LOCAL MODE
      ENTITY Vehicle
      UPDATE FIELDS ( Status )
      WITH lt_updates
      REPORTED DATA(mod_reported)
      FAILED DATA(mod_failed).

      reported-vehicle = VALUE #( BASE reported-vehicle ( LINES OF mod_reported-vehicle ) ).
      failed-vehicle = VALUE #( BASE failed-vehicle ( LINES OF mod_failed-vehicle ) ).
    ENDIF.

    " Read back updated result
    READ ENTITIES OF zfleet_r_vehicle IN LOCAL MODE
    ENTITY Vehicle
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(result_vehicles).

    result = VALUE #( FOR v IN result_vehicles (
        %tky = v-%tky
        %param = v
     ) ).

  ENDMETHOD.

  METHOD returnToService.

    READ ENTITIES OF zfleet_r_vehicle IN LOCAL MODE
    ENTITY Vehicle
    FIELDS ( Status ) WITH CORRESPONDING #( keys )
    RESULT DATA(vehicles).

    DATA lt_updates TYPE TABLE FOR UPDATE zfleet_r_vehicle\\Vehicle.

    LOOP AT vehicles INTO DATA(vehicle).
      IF vehicle-Status <> 'REPAIR'.
        APPEND VALUE #(
            %tky = vehicle-%tky
            %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-error
                text = 'Only vehicles under repair can be returned to service.'
             )
         ) TO reported-vehicle.
        APPEND VALUE #( %tky = vehicle-%tky ) TO failed-vehicle.
        CONTINUE.
      ENDIF.

      " Update vehicle status
      APPEND VALUE #(
          %tky = vehicle-%tky
          status = 'INSERVICE'
       ) TO lt_updates.

    ENDLOOP.

    IF lt_updates IS NOT INITIAL.
      MODIFY ENTITIES OF zfleet_r_vehicle IN LOCAL MODE
      ENTITY Vehicle
      UPDATE FIELDS ( Status )
      WITH lt_updates
      REPORTED DATA(mod_reported)
      FAILED DATA(mod_failed).

      reported-vehicle = VALUE #( BASE reported-vehicle ( LINES OF mod_reported-vehicle ) ).
      failed-vehicle = VALUE #( BASE failed-vehicle ( LINES OF mod_failed-vehicle ) ).
    ENDIF.


    " Read back updated result
    READ ENTITIES OF zfleet_r_vehicle IN LOCAL MODE
    ENTITY Vehicle
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(result_vehicles).

    result = VALUE #( FOR v IN result_vehicles (
        %tky = v-%tky
        %param = v
     ) ).


  ENDMETHOD.

  METHOD sendToRepair.

    READ ENTITIES OF zfleet_r_vehicle IN LOCAL MODE
    ENTITY Vehicle
    FIELDS ( Status ) WITH CORRESPONDING #( keys )
    RESULT DATA(vehicles).

    DATA lt_updates TYPE TABLE FOR UPDATE zfleet_r_vehicle\\Vehicle.
    DATA lt_log_creates TYPE TABLE FOR CREATE zfleet_r_vehicle\\Vehicle\_Logs.

    LOOP AT vehicles INTO DATA(vehicle).
      IF vehicle-Status <> 'INSERVICE'.
        APPEND VALUE #(
            %tky = vehicle-%tky
            %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-error
                text = 'Only In Service vehicles can be sent to repair.'
             )
         ) TO reported-vehicle.
        APPEND VALUE #( %tky = vehicle-%tky ) TO failed-vehicle.
        CONTINUE.
      ENDIF.

      " Update vehicle status
      APPEND VALUE #(
          %tky = vehicle-%tky
          status = 'REPAIR'
       ) TO lt_updates.

      " Auto-create an OPEN repair log entry
      APPEND VALUE #(
         %tky = vehicle-%tky
         %target = VALUE #( (
             %cid = vehicle-VehicleUUID
             logtype = 'REPAIR'
             description = |Sent to repair on { cl_abap_context_info=>get_system_date(  ) }|
             status = 'OPEN'
             startdate = cl_abap_context_info=>get_system_date(  )
          ) )
       ) TO lt_log_creates.
    ENDLOOP.

    MODIFY ENTITIES OF zfleet_r_vehicle IN LOCAL MODE
    ENTITY Vehicle
    UPDATE FIELDS ( Status )
    WITH lt_updates
    ENTITY Vehicle
    CREATE BY \_Logs FROM lt_log_creates
    REPORTED DATA(mod_reported)
    FAILED DATA(mod_failed).

    " Read back updated result
    READ ENTITIES OF zfleet_r_vehicle IN LOCAL MODE
    ENTITY Vehicle
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(result_vehicles).

    result = VALUE #( FOR v IN result_vehicles (
        %tky = v-%tky
        %param = v
     ) ).

    reported = CORRESPONDING #( DEEP mod_reported ).
    failed = CORRESPONDING #( DEEP mod_failed ).

  ENDMETHOD.

  METHOD validateRetireConditions.

    " Block retirement if open maintenance logs exist
    READ ENTITIES OF zfleet_r_vehicle IN LOCAL MODE
    ENTITY Vehicle
    FIELDS ( Status )
    WITH CORRESPONDING #( keys )
    RESULT DATA(vehicles).

    LOOP AT vehicles INTO DATA(vehicle).
      CHECK vehicle-Status = 'RETIRED'.

      " Check for active logs in the child entity
      READ ENTITIES OF zfleet_r_vehicle IN LOCAL MODE
      ENTITY Vehicle BY \_Logs
      FIELDS ( Status )
      WITH VALUE #( ( %tky = vehicle-%tky ) )
      RESULT DATA(logs).

      DATA(lv_active_count) = REDUCE i(
          INIT c = 0 FOR log IN logs
          WHERE ( Status = 'OPEN' OR Status = 'INPROGRESS' )
          NEXT c += 1
      ).

      APPEND VALUE #(
          %tky        = vehicle-%tky
          %state_area = 'VALIDATE_RETIRE'
      ) TO reported-vehicle.

      IF lv_active_count > 0.
        APPEND VALUE #(
            %tky = vehicle-%tky
            %state_area = 'VALIDATE_RETIRE'
            %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-error
                text = |Cannot retire: { lv_active_count } active maintenance log(s) exist.|
             )
            %element-Status = if_abap_behv=>mk-on
         ) TO reported-vehicle.
        APPEND VALUE #( %tky = vehicle-%tky ) TO failed-vehicle.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateStatusTransition.

    " Guard illegal state transitions using a whitelist approach
    READ ENTITIES OF zfleet_r_vehicle IN LOCAL MODE
    ENTITY Vehicle
    FIELDS ( Status )
    WITH CORRESPONDING #( keys )
    RESULT DATA(vehicles).

    " Read persisted (committed) status from DB for comparison
    SELECT vehicle_uuid, status
    FROM zfleet_avhcle
    FOR ALL ENTRIES IN @vehicles
    WHERE vehicle_uuid =  @vehicles-VehicleUUID
    INTO TABLE @DATA(db_vehicles).

    LOOP AT vehicles INTO DATA(vehicle).
      READ TABLE db_vehicles WITH KEY vehicle_uuid = vehicle-VehicleUUID INTO DATA(db_vehicle).

      " new record, skip
      IF sy-subrc <> 0. RETURN. ENDIF.

      DATA(lv_old) = db_vehicle-status.
      DATA(lv_new) = vehicle-Status.

      " Define allowed transitions
      DATA lv_valid TYPE abap_bool.
      lv_valid = SWITCH #( lv_old
          WHEN 'INSERVICE' THEN COND #( WHEN lv_new = 'INSERVICE'
                                          OR lv_new = 'REPAIR'
                                          OR lv_new = 'RETIRED'
          THEN abap_true ELSE abap_false )
          WHEN 'REPAIR' THEN COND #( WHEN lv_new = 'REPAIR'
                                       OR lv_new = 'INSERVICE'
                                       OR lv_new = 'RETIRED'
          THEN abap_true ELSE abap_false )
          WHEN 'RETIRED' THEN COND #( WHEN lv_new = 'RETIRED' THEN abap_true ELSE abap_false )
          ELSE abap_false
       ).

      APPEND VALUE #(
         %tky        = vehicle-%tky
         %state_area = 'VALIDATE_STATUS'
     ) TO reported-vehicle.

      IF lv_valid = abap_false.
        APPEND VALUE #(
            %tky = vehicle-%tky
            %state_area = 'VALIDATE_STATUS'
            %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-error
                text = |Invalid status transition: { lv_old } to { lv_new }.|
             )
            %element-Status = if_abap_behv=>mk-on
         ) TO reported-vehicle.
        APPEND VALUE #( %tky = vehicle-%tky ) TO failed-vehicle.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateRequiredFields.

    READ ENTITIES OF zfleet_r_vehicle IN LOCAL MODE
    ENTITY Vehicle
    FIELDS ( Description VehicleType LicensePlate AcquisitionDate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(vehicles).

    LOOP AT vehicles INTO DATA(vehicle).
      APPEND VALUE #(
        %tky        = vehicle-%tky
        %state_area = 'VALIDATE_REQUIRED'
    ) TO reported-vehicle.

      IF vehicle-Description IS INITIAL.
        APPEND VALUE #( %tky = vehicle-%tky ) TO failed-vehicle.
        APPEND VALUE #(
            %tky = vehicle-%tky
            %state_area = 'VALIDATE_REQUIRED'
            %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-error
                text = 'Description is required.'
             )
            %element-Description = if_abap_behv=>mk-on
        ) TO reported-vehicle.
      ENDIF.

      IF vehicle-VehicleType IS INITIAL.
        APPEND VALUE #( %tky = vehicle-%tky ) TO failed-vehicle.
        APPEND VALUE #(
            %tky = vehicle-%tky
            %state_area = 'VALIDATE_REQUIRED'
            %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-error
                text = 'Vehicle Type is required.'
             )
            %element-VehicleType = if_abap_behv=>mk-on
        ) TO reported-vehicle.
      ENDIF.

      IF vehicle-LicensePlate IS INITIAL.
        APPEND VALUE #( %tky = vehicle-%tky ) TO failed-vehicle.
        APPEND VALUE #(
            %tky = vehicle-%tky
            %state_area = 'VALIDATE_REQUIRED'
            %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-error
                text = 'License Plate is required.'
             )
            %element-LicensePlate = if_abap_behv=>mk-on
        ) TO reported-vehicle.
      ENDIF.

      IF vehicle-AcquisitionDate IS INITIAL.
        APPEND VALUE #( %tky = vehicle-%tky ) TO failed-vehicle.
        APPEND VALUE #(
            %tky = vehicle-%tky
            %state_area = 'VALIDATE_REQUIRED'
            %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-error
                text = 'Acquisition Date is required.'
             )
            %element-AcquisitionDate = if_abap_behv=>mk-on
        ) TO reported-vehicle.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD setInitialStatus.

    READ ENTITIES OF zfleet_r_vehicle IN LOCAL MODE
    ENTITY Vehicle
    FIELDS ( Status )
    WITH CORRESPONDING #( keys )
    RESULT DATA(vehicles).

    " If status is already set, do nothing
    DELETE vehicles WHERE Status IS NOT INITIAL.
    CHECK vehicles IS NOT INITIAL.

    " Else set status to INSERVICE
    MODIFY ENTITIES OF zfleet_r_vehicle IN LOCAL MODE
    ENTITY Vehicle
    UPDATE FIELDS ( Status )
    WITH VALUE #( FOR vehicle IN vehicles ( %tky = vehicle-%tky Status = 'INSERVICE' ) )
    REPORTED DATA(update_reported).

    " Set changing param reported
    reported = CORRESPONDING #( DEEP update_reported ).

  ENDMETHOD.

  METHOD get_instance_features.

    READ ENTITIES OF zfleet_r_vehicle IN LOCAL MODE
    ENTITY Vehicle
    FIELDS ( VehicleID Status )
    WITH CORRESPONDING #( keys )
    RESULT DATA(vehicles)
    FAILED failed.

    " evaluate the conditions, set the operation state, and set result parameter
    result = VALUE #( FOR vehicle IN vehicles (
        %tky = vehicle-%tky
        %features-%update = COND #( WHEN vehicle-Status = 'RETIRED' THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled )
        %features-%delete = COND #( WHEN vehicle-Status = 'INSERVICE' THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
        %action-Edit = COND #( WHEN vehicle-Status = 'RETIRED' THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled )
        %action-sendToRepair = COND #( WHEN vehicle-Status = 'INSERVICE' THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
        %action-returnToService = COND #( WHEN vehicle-Status = 'REPAIR' THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
        %action-retireVehicle = COND #( WHEN vehicle-Status = 'RETIRED' THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled )
     ) ).

  ENDMETHOD.

ENDCLASS.
