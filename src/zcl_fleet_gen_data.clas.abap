CLASS zcl_fleet_gen_data DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_FLEET_GEN_DATA IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    GET TIME STAMP FIELD DATA(tsl).

    DATA lt_vehicle TYPE TABLE OF zfleet_avhcle.
    DATA lt_log TYPE TABLE OF zfleet_amaintlog.

    DATA(v1_uuid) = xco_cp=>uuid(  )->value.
    DATA(v2_uuid) = xco_cp=>uuid(  )->value.
    DATA(v3_uuid) = xco_cp=>uuid(  )->value.
    DATA(v4_uuid) = xco_cp=>uuid(  )->value.
    DATA(v5_uuid) = xco_cp=>uuid(  )->value.
    DATA(v6_uuid) = xco_cp=>uuid(  )->value.
    DATA(v7_uuid) = xco_cp=>uuid(  )->value.

    lt_vehicle = VALUE #(
      (
          vehicle_uuid = v1_uuid
          vehicle_id = '00000010'
          description = 'Ford Transit Cargo Van'
          vehicle_type = 'Van'
          license_plate = 'KAA 123X'
          status = 'INSERVICE'
          status_criticality = '3'
          acquisition_date = '20210315'
          mileage = 87400
          distance_unit = 'KM'
          responsible_person = 'Jeremy Mwangi'
          created_by = sy-uname
          created_at = tsl
          local_last_changed_by = sy-uname
          local_last_changed_at = tsl
          last_changed_at = tsl
      )
      (
          vehicle_uuid = v2_uuid
          vehicle_id = '00000011'
          description = 'Toyota Land Cruiser 200'
          vehicle_type = 'SUV'
          license_plate = 'KBZ 456Y'
          status = 'INSERVICE'
          status_criticality = '3'
          acquisition_date = '20190801'
          mileage = 214300
          distance_unit = 'KM'
          responsible_person = 'Agnes Ochieng'
          created_by = sy-uname
          created_at = tsl
          local_last_changed_by = sy-uname
          local_last_changed_at = tsl
          last_changed_at = tsl
      )
      (
          vehicle_uuid = v3_uuid
          vehicle_id = '00000012'
          description = 'Isuzu NQR 33 Seater Bus'
          vehicle_type = 'Bus'
          license_plate = 'KCC 789Z'
          status = 'REPAIR'
          status_criticality = '2'
          acquisition_date = '20180601'
          mileage = 312500
          distance_unit = 'KM'
          responsible_person = 'Simon Kamau'
          created_by = sy-uname
          created_at = tsl
          local_last_changed_by = sy-uname
          local_last_changed_at = tsl
          last_changed_at = tsl
      )
      (
          vehicle_uuid = v4_uuid
          vehicle_id = '00000013'
          description = 'Mitsubishi Fuso Fighter Truck'
          vehicle_type = 'Truck'
          license_plate = 'KDA 321A'
          status = 'REPAIR'
          status_criticality = '2'
          acquisition_date = '20200210'
          mileage = 178900
          distance_unit = 'KM'
          responsible_person = 'Freddy Njenga'
          created_by = sy-uname
          created_at = tsl
          local_last_changed_by = sy-uname
          local_last_changed_at = tsl
          last_changed_at = tsl
      )
      (
          vehicle_uuid = v5_uuid
          vehicle_id = '00000014'
          description = 'Nissan Navara Double Cab Pickup'
          vehicle_type = 'Pickup'
          license_plate = 'KDE 654B'
          status = 'INSERVICE'
          status_criticality = '3'
          acquisition_date = '20220901'
          mileage = 41200
          distance_unit = 'KM'
          responsible_person = 'Bernice Wanjiku'
          created_by = sy-uname
          created_at = tsl
          local_last_changed_by = sy-uname
          local_last_changed_at = tsl
          last_changed_at = tsl
      )
      (
          vehicle_uuid = v6_uuid
          vehicle_id = '00000015'
          description = 'Caterpillar GP25N Forklift'
          vehicle_type = 'Machine'
          license_plate = 'INTERNAL01'
          status = 'RETIRED'
          status_criticality = '1'
          acquisition_date = '20120401'
          mileage = 0
          distance_unit = 'KM'
          responsible_person = 'Jeremy Mwangi'
          created_by = sy-uname
          created_at = tsl
          local_last_changed_by = sy-uname
          local_last_changed_at = tsl
          last_changed_at = tsl
      )
      (
          vehicle_uuid = v7_uuid
          vehicle_id = '00000016'
          description = 'Tata Prima 4028.S Tipper Truck'
          vehicle_type = 'Truck'
          license_plate = 'KDF 900C'
          status = 'INSERVICE'
          status_criticality = '3'
          acquisition_date = '20230301'
          mileage = 19800
          distance_unit = 'KM'
          responsible_person = 'Agnes Ochieng'
          created_by = sy-uname
          created_at = tsl
          local_last_changed_by = sy-uname
          local_last_changed_at = tsl
          last_changed_at = tsl
      )
     ).

    lt_log = VALUE #(
    " Vehicle 1 — Ford Transit: 2 completed routine service logs
         (
              log_uuid        = xco_cp=>uuid(  )->value
              vehicle_uuid        = v1_uuid
              log_id              = '00000020'
              log_type            = 'SERVICE'
              description         = '10,000 km routine service — oil, filters, brakes checked'
              status              = 'COMPLETED'
              assigned_technician = 'TECH01'
              start_date          = '20240110'
              end_date            = '20240110'
              cost                = '8500.00'
              currency_code = 'KES'
              created_by = sy-uname
              created_at = tsl
              local_last_changed_by = sy-uname
              local_last_changed_at = tsl
              last_changed_at = tsl
         )
         (
              log_uuid        = xco_cp=>uuid(  )->value
              vehicle_uuid        = v1_uuid
              log_id              = '00000021'
              log_type            = 'INSPECTION'
              description         = 'Annual roadworthiness inspection — NTSA compliance'
              status              = 'COMPLETED'
              assigned_technician = 'TECH02'
              start_date          = '20240815'
              end_date            = '20240815'
              cost                = '3200.00'
              currency_code = 'KES'
              created_by = sy-uname
              created_at = tsl
              local_last_changed_by = sy-uname
              local_last_changed_at = tsl
              last_changed_at = tsl
         )
         " Vehicle 2 — Land Cruiser: 1 completed, 1 open upcoming service
         (
              log_uuid        = xco_cp=>uuid(  )->value
              vehicle_uuid        = v2_uuid
              log_id              = '00000022'
              log_type            = 'SERVICE'
              description         = 'Gearbox oil change and diff service at 210,000 km'
              status              = 'COMPLETED'
              assigned_technician = 'TECH01'
              start_date          = '20241001'
              end_date            = '20241002'
              cost                = '24500.00'
              currency_code = 'KES'
              created_by = sy-uname
              created_at = tsl
              local_last_changed_by = sy-uname
              local_last_changed_at = tsl
              last_changed_at = tsl
         )
         (
              log_uuid        = xco_cp=>uuid(  )->value
              vehicle_uuid        = v2_uuid
              log_id              = '00000023'
              log_type            = 'SERVICE'
              description         = 'Scheduled 215,000 km full service — due this month'
              status              = 'OPEN'
              assigned_technician = 'TECH03'
              start_date          = '20260520'
              end_date            = '00000000'
              cost                = '0.00'
              currency_code = 'KES'
              created_by = sy-uname
              created_at = tsl
              local_last_changed_by = sy-uname
              local_last_changed_at = tsl
              last_changed_at = tsl
         )
         " Vehicle 3 — Isuzu Bus (REPAIR): 1 completed, 1 in-progress repair
         (
              log_uuid        = xco_cp=>uuid(  )->value
              vehicle_uuid        = v3_uuid
              log_id              = '00000024'
              log_type            = 'SERVICE'
              description         = 'Brake pad replacement and wheel alignment'
              status              = 'COMPLETED'
              assigned_technician = 'TECH02'
              start_date          = '20250301'
              end_date            = '20250301'
              cost                = '18700.00'
              currency_code = 'KES'
              created_by = sy-uname
              created_at = tsl
              local_last_changed_by = sy-uname
              local_last_changed_at = tsl
              last_changed_at = tsl
         )
         (
              log_uuid        = xco_cp=>uuid(  )->value
              vehicle_uuid        = v3_uuid
              log_id              = '00000025'
              log_type            = 'REPAIR'
              description         = 'Engine overhaul — excessive oil consumption diagnosed'
              status              = 'INPROGRESS'
              assigned_technician = 'TECH01'
              start_date          = '20260501'
              end_date            = '00000000'
              cost                = '0.00'
              currency_code = 'KES'
              created_by = sy-uname
              created_at = tsl
              local_last_changed_by = sy-uname
              local_last_changed_at = tsl
              last_changed_at = tsl
         )
         " Vehicle 4 — Mitsubishi Truck (REPAIR): 2 open logs
         " (demonstrates that retirement would be blocked)
         (
              log_uuid        = xco_cp=>uuid(  )->value
              vehicle_uuid        = v4_uuid
              log_id              = '00000026'
              log_type            = 'REPAIR'
              description         = 'Transmission failure — gearbox replacement required'
              status              = 'OPEN'
              assigned_technician = 'TECH04'
              start_date          = '20260428'
              end_date            = '00000000'
              cost                = '0.00'
              currency_code = 'KES'
              created_by = sy-uname
              created_at = tsl
              local_last_changed_by = sy-uname
              local_last_changed_at = tsl
              last_changed_at = tsl
         )
         (
              log_uuid        = xco_cp=>uuid(  )->value
              vehicle_uuid        = v4_uuid
              log_id              = '00000027'
              log_type            = 'INSPECTION'
              description         = 'Pre-repair electrical systems diagnostic'
              status              = 'INPROGRESS'
              assigned_technician = 'TECH03'
              start_date          = '20260429'
              end_date            = '00000000'
              cost                = '0.00'
              currency_code = 'KES'
              created_by = sy-uname
              created_at = tsl
              local_last_changed_by = sy-uname
              local_last_changed_at = tsl
              last_changed_at = tsl
         )
         " Vehicle 5 — Nissan Navara: 1 completed inspection only
         (
              log_uuid        = xco_cp=>uuid(  )->value
              vehicle_uuid        = v5_uuid
              log_id              = '00000028'
              log_type            = 'INSPECTION'
              description         = 'New vehicle pre-delivery inspection and PDI sign-off'
              status              = 'COMPLETED'
              assigned_technician = 'TECH02'
              start_date          = '20220905'
              end_date            = '20220905'
              cost                = '1500.00'
              currency_code = 'KES'
              created_by = sy-uname
              created_at = tsl
              local_last_changed_by = sy-uname
              local_last_changed_at = tsl
              last_changed_at = tsl
         )
         " Vehicle 6 — Caterpillar Forklift (RETIRED): 3 completed logs
         " (demonstrates retirement is valid — no open logs)
         (
              log_uuid        = xco_cp=>uuid(  )->value
              vehicle_uuid        = v6_uuid
              log_id              = '00000029'
              log_type            = 'REPAIR'
              description         = 'Hydraulic pump seal replacement — final major repair'
              status              = 'COMPLETED'
              assigned_technician = 'TECH01'
              start_date          = '20231101'
              end_date            = '20231115'
              cost                = '67000.00'
              currency_code = 'KES'
              created_by = sy-uname
              created_at = tsl
              local_last_changed_by = sy-uname
              local_last_changed_at = tsl
              last_changed_at = tsl
         )
         (
              log_uuid        = xco_cp=>uuid(  )->value
              vehicle_uuid        = v6_uuid
              log_id              = '00000030'
              log_type            = 'INSPECTION'
              description         = 'End-of-life condition assessment — decommission approved'
              status              = 'COMPLETED'
              assigned_technician = 'TECH04'
              start_date          = '20240201'
              end_date            = '20240201'
              cost                = '5000.00'
              currency_code = 'KES'
              created_by = sy-uname
              created_at = tsl
              local_last_changed_by = sy-uname
              local_last_changed_at = tsl
              last_changed_at = tsl
         )
         (
              log_uuid        = xco_cp=>uuid(  )->value
              vehicle_uuid        = v6_uuid
              log_id              = '00000031'
              log_type            = 'SERVICE'
              description         = 'Final service and asset write-off documentation completed'
              status              = 'COMPLETED'
              assigned_technician = 'TECH02'
              start_date          = '20240210'
              end_date            = '20240210'
              cost                = '2000.00'
              currency_code = 'KES'
              created_by = sy-uname
              created_at = tsl
              local_last_changed_by = sy-uname
              local_last_changed_at = tsl
              last_changed_at = tsl
         )
         " Vehicle 7 — Tata Tipper: 1 completed service log
         (
              log_uuid        = xco_cp=>uuid(  )->value
              vehicle_uuid        = v7_uuid
              log_id              = '00000032'
              log_type            = 'SERVICE'
              description         = 'First service at 20,000 km — oil change and chassis inspection'
              status              = 'COMPLETED'
              assigned_technician = 'TECH03'
              start_date          = '20260402'
              end_date            = '20260402'
              cost                = '12000.00'
              currency_code = 'KES'
              created_by = sy-uname
              created_at = tsl
              local_last_changed_by = sy-uname
              local_last_changed_at = tsl
              last_changed_at = tsl
         )
     ).

    DELETE FROM zfleet_avhcle.
    INSERT zfleet_avhcle FROM TABLE @lt_vehicle.
    out->write( |Db table successfully filled with vehicle data.| ).

    DELETE FROM zfleet_amaintlog.
    INSERT zfleet_amaintlog FROM TABLE @lt_log.
    out->write( |Db table successfully filled with log data.| ).

  ENDMETHOD.
ENDCLASS.
