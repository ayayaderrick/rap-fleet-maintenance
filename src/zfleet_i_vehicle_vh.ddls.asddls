@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help For Vehicles'
@Metadata.ignorePropagatedAnnotations: true
@Search.searchable: true
define view entity ZFLEET_I_VEHICLE_VH
  as select from ZFLEET_R_VEHICLE
{
      @UI.hidden: true
  key VehicleUUID,
      @Search.defaultSearchElement: true
      VehicleID,
      @Search.defaultSearchElement: true
      VehicleType,
      @Search.defaultSearchElement: true
      LicensePlate
}
