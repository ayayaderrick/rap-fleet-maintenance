@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help For Vehicle Status'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZFLEET_I_VEHSTATUS_VH
  as select from DDCDS_CUSTOMER_DOMAIN_VALUE_T(p_domain_name: 'ZVEH_STATUS')
{
      @UI.hidden: true
  key domain_name,
      @UI.hidden: true
  key value_position,
      @UI.hidden: true
  key language,
      @ObjectModel.text.element: [ 'StatusText' ]
      value_low as Status,
      text      as StatusText
}
