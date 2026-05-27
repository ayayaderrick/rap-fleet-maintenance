@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@EndUserText: {
  label: 'Vehicle Details'
}
@ObjectModel: {
  sapObjectNodeType.name: 'ZFLEET_AVEHICLE'
}
@OData.entityType.name: 'Vehicle_Type'
@AccessControl.authorizationCheck: #MANDATORY
@Search.searchable: true
define root view entity ZFLEET_C_VEHICLE
  provider contract transactional_query
  as projection on ZFLEET_R_VEHICLE
  association [1..1] to ZFLEET_R_VEHICLE as _BaseEntity on $projection.VehicleUUID = _BaseEntity.VehicleUUID
{
  key VehicleUUID,
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.9
      VehicleID,
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.9
      Description,
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.9
      VehicleType,
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.9
      LicensePlate,
      @Consumption.valueHelpDefinition: [{
        entity : { name: 'ZFLEET_I_VEHSTATUS_VH', element: 'Status' },
        useForValidation: true
       }]
      @ObjectModel.text.element: [ 'StatusText' ]
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.9
      Status,
      _StatusVH.StatusText,
      StatusCriticality,
      AcquisitionDate,
      @Semantics: {
        quantity.unitOfMeasure: 'DistanceUnit'
      }
      Mileage,
      @Consumption: {
        valueHelpDefinition: [ {
          entity.element: 'UnitOfMeasure',
          entity.name: 'I_UnitOfMeasureStdVH',
          useForValidation: true
        } ]
      }
      DistanceUnit,
      ResponsiblePerson,
      @Semantics: {
        user.createdBy: true
      }
      CreatedBy,
      @Semantics: {
        systemDateTime.createdAt: true
      }
      CreatedAt,
      @Semantics: {
        user.localInstanceLastChangedBy: true
      }
      LocalLastChangedBy,
      @Semantics: {
        systemDateTime.localInstanceLastChangedAt: true
      }
      LocalLastChangedAt,
      @Semantics: {
        systemDateTime.lastChangedAt: true
      }
      LastChangedAt,
      _BaseEntity,
      _Logs : redirected to composition child ZFLEET_C_MAINTLOG

}
