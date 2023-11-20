@EndUserText.label: 'Consumption View SO'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: false
@Search.searchable: true
define root view entity ZC_SALES_ORDER_RAP
  provider contract transactional_query
  as projection on ZI_SALES_ORDER_RAP
{
      @EndUserText.label: 'Sales Order'
      //      @Consumption.valueHelpDefinition: [{
      //                entity: {
      //                            name: 'I_SALESDOCUMENTBASIC',
      //                            element: 'SalesDocument'
      //                        }
      //      }]
      @Search.defaultSearchElement: true
  key SalesOrder,
      @EndUserText.label: 'Date Created'
      CreationDate,
      @EndUserText.label: 'Creation Time'
      CreationTime,
      CreatedBy,
      DocumentCategory,
      TransactionGroup,

      @Consumption.valueHelpDefinition: [{
                    entity: {
                                name: 'ZI_SO_TEXT_VH',
                                element: 'SalesDocType'
                            },
                    additionalBinding: [{ localElement: 'DocumentTypeText' ,
                                          element: 'SalesDocTypeText',
                                          usage: #FILTER_AND_RESULT }]
      }]
      @EndUserText.label: 'Document Type'
      @ObjectModel.text.element: [ 'DocumentTypeText' ]
      DocumentType,

      //  If the keyword localized is used, the text in the system log-on language is drawn.
      _SalesDocTypeText.SalesDocTypeText as DocumentTypeText : localized,
      NetPrice,
      Currency,
      @ObjectModel.text.element: [ 'StatusText' ]
      OverallStatus,
      StatusText,
      OverallStatusCriticality,
      LastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      LastChangedAt,

      _SalesDocTypeText,
      _SalesOrderItem : redirected to composition child ZC_SO_ITEM_RAP


}
