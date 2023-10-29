@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface View SO'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define root view entity ZI_SALES_ORDER_RAP
  as select from zsales_order_rap
  association [0..1] to I_SalesDocumentTypeText as _SalesDocTypeText on  _SalesDocTypeText.SalesDocumentType = $projection.DocumentType
                                                                     and _SalesDocTypeText.Language          = $session.system_language
  composition [0..*] of ZI_SO_ITEM_RAP          as _SalesOrderItem
{
  key vbeln                                   as SalesOrder,
      @Semantics.systemDate.createdAt: true
      erdat                                   as CreationDate,
      @Semantics.systemTime.createdAt: true
      erzet                                   as CreationTime,
      @Semantics.user.createdBy: true
      ernam                                   as CreatedBy,
      vbtyp                                   as DocumentCategory,
      trvog                                   as TransactionGroup,
      auart                                   as DocumentType,
      @Semantics.amount.currencyCode: 'Currency'
      netwr                                   as NetPrice,
      waerk                                   as Currency,


      uvall                                   as OverallStatus,

      case uvall when 'A' then 'Not Yet Processed'
                 when 'C' then 'Completely Processed'
                 else 'Unknown Status'
                 end                          as StatusText,

      case uvall
      when ''  then 2     -- 'Not Relevant'           | 2: yellow colour
      when 'C'  then 3    -- 'Completely Processed'   | 3: green colour
      when 'A'  then 1    -- 'Not Yet Processed'      | 1: red colour
      else 0              -- 'nothing'                | 0: unknown
      end                                     as OverallStatusCriticality,

      @Semantics.user.lastChangedBy: true
      last_changed_by                         as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at                         as LastChangedAt,

      $session.system_language                as language,
      _SalesDocTypeText.SalesDocumentTypeName as DocumentTypeText,

      _SalesDocTypeText,
      _SalesOrderItem

}
