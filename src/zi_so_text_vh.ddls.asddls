@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help for SO Type Text'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
@ObjectModel.dataCategory: #TEXT
@Search.searchable: true
@Consumption.valueHelpDefault.fetchValues: #AUTOMATICALLY_WHEN_DISPLAYED
define view entity ZI_SO_TEXT_VH
  as select from zso_typ_text_vh
{
      @Search.defaultSearchElement: true
  key auart   as SalesDocType,
      @Semantics.language: true
  key spras   as Language,
      @Semantics.text: true
      so_text as SalesDocTypeText
}

