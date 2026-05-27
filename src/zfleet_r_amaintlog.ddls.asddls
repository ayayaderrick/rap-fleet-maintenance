@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
@ObjectModel.sapObjectNodeType.name: 'ZFLEET_AMAINTLOG'
@EndUserText.label: '###GENERATED Core Data Service Entity'
define view entity ZFLEET_R_AMAINTLOG
  as select from zfleet_amaintlog as Logs
  association to parent ZFLEET_R_VEHICLE as _Vehicle     on $projection.VehicleUUID = _Vehicle.VehicleUUID
  association to ZFLEET_I_LOGSTATUS_VH   as _LogStatusVH on $projection.Status = _LogStatusVH.Status
{
  key  log_uuid              as LogUUID,
       vehicle_uuid          as VehicleUUID,
       log_id                as LogID,
       log_type              as LogType,
       description           as Description,
       status                as Status,
       assigned_technician   as AssignedTechnician,
       start_date            as StartDate,
       end_date              as EndDate,
       @Semantics.amount.currencyCode: 'CurrencyCode'
       cost                  as Cost,
       @Consumption.valueHelpDefinition: [ {
         entity.name: 'I_CurrencyStdVH',
         entity.element: 'Currency',
         useForValidation: true
       } ]
       currency_code         as CurrencyCode,
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

       _Vehicle,
       _LogStatusVH
}
