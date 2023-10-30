@AbapCatalog.viewEnhancementCategory: [ #NONE ]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface View for SO Items'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZI_SO_ITEM_RAP
  as select from zso_item_rap
  association to parent ZI_SALES_ORDER_RAP as _SalesOrderHeader on $projection.SalesOrder = _SalesOrderHeader.SalesOrder
{

  key vbeln           as SalesOrder,
  key posnr           as ItemNo,
      matnr           as Material,
      matext          as MaterialDescription,
      matwa           as MaterialEntered,
      pstyv           as ItemCategory,
      werks           as Plant,
      @Semantics.quantity.unitOfMeasure: 'UnitOfMeasurement'
      zmeng           as TargetQuantity,
      zieme           as UnitOfMeasurement,
      @Semantics.amount.currencyCode: 'Currency'
      netwr           as ItemAmount,
      waerk           as Currency,
      last_changed_by as LastChangedBy,
      last_changed_at as LastChangedAt,

      _SalesOrderHeader
}
