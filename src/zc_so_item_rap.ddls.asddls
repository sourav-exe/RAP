@EndUserText.label: 'Consumption View SO Items'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
define view entity ZC_SO_ITEM_RAP
  as projection on ZI_SO_ITEM_RAP
{
      @Search.defaultSearchElement: true
  key SalesOrder,
  key ItemNo,
      //      @Consumption.valueHelpDefinition: [{
      //                       entity:{
      //                                name: 'I_MaterialText',
      //                                element: 'Material'
      //                       },
      //                       additionalBinding: [{
      //                                             localElement: 'MaterialDescription',
      //                                             element: 'MaterialName',
      //                                             usage: #FILTER_AND_RESULT
      //                       }],
      //                       distinctValues: true
      //
      //       }]
      @ObjectModel.text.element: [ 'MaterialDescription' ]
      Material,
      MaterialDescription,
      MaterialEntered,
      ItemCategory,
      Plant,
      TargetQuantity,
      UnitOfMeasurement,
      ItemAmount,
      Currency,
      LastChangedBy,
      LastChangedAt,
      /* Associations */
      _SalesOrderHeader : redirected to parent ZC_SALES_ORDER_RAP
}
