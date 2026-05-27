@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@EndUserText: {
  label: 'Maintenance Log Details'
}

@AccessControl.authorizationCheck: #MANDATORY
define view entity ZFLEET_C_MAINTLOG
  as projection on ZFLEET_R_AMAINTLOG
{
  key LogUUID,
      VehicleUUID,
      LogID,
      LogType,
      Description,
      @Consumption.valueHelpDefinition: [{
        entity : { name: 'ZFLEET_I_LOGSTATUS_VH', element: 'Status' },
        useForValidation: true
       }]
      @ObjectModel.text.element: [ 'StatusText' ]
      Status,
      _LogStatusVH.StatusText,
      AssignedTechnician,
      StartDate,
      EndDate,
      @Semantics: {
        amount.currencyCode: 'CurrencyCode'
      }
      Cost,
      @Consumption: {
        valueHelpDefinition: [ {
          entity.element: 'Currency',
          entity.name: 'I_CurrencyStdVH',
          useForValidation: true
        } ]
      }
      CurrencyCode,
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

      _Vehicle : redirected to parent ZFLEET_C_VEHICLE
}
