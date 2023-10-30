@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help for SO Type Text'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZI_SO_TEXT_VH
  as select from zso_typ_text_vh
{
  key auart   as SalesDocType,
  key spras   as Language,
      so_text as SalesDocTypeText
}
where
  spras = $session.system_language
