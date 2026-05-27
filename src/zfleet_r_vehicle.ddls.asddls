@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
@ObjectModel.sapObjectNodeType.name: 'ZFLEET_AVEHICLE'
@EndUserText.label: '###GENERATED Core Data Service Entity'
define root view entity ZFLEET_R_VEHICLE
  as select from zfleet_avhcle as Vehicle
  composition [0..*] of ZFLEET_R_AMAINTLOG    as _Logs
  association [0..1] to ZFLEET_I_VEHSTATUS_VH as _StatusVH on $projection.Status = _StatusVH.Status
{
  key  vehicle_uuid          as VehicleUUID,
       vehicle_id            as VehicleID,
       description           as Description,
       vehicle_type          as VehicleType,
       license_plate         as LicensePlate,
       status                as Status,
       status_criticality    as StatusCriticality,
       acquisition_date      as AcquisitionDate,
       @Semantics.quantity.unitOfMeasure: 'DistanceUnit'
       mileage               as Mileage,
       @Consumption.valueHelpDefinition: [ {
         entity.name: 'I_UnitOfMeasureStdVH',
         entity.element: 'UnitOfMeasure',
         useForValidation: true
       } ]
       distance_unit         as DistanceUnit,
       responsible_person    as ResponsiblePerson,
       @Semantics.user.createdBy: true
       created_by            as CreatedBy,
       @Semantics.systemDateTime.createdAt: true
       created_at            as CreatedAt,
       @Semantics.user.localInstanceLastChangedBy: true
       local_last_changed_by as LocalLastChangedBy,
       @Semantics.systemDateTime.localInstanceLastChangedAt: true
       local_last_changed_at as LocalLastChangedAt,
       @Semantics.systemDateTime.lastChangedAt: true
       last_changed_at       as LastChangedAt,

       _Logs,
       _StatusVH
}
