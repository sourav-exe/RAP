@EndUserText.label: 'Consumption View SO'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: false
@Search.searchable: true
define root view entity ZC_SALES_ORDER_RAP
  as projection on ZI_SALES_ORDER_RAP
{
      @EndUserText.label: 'Sales Order'
      @Consumption.valueHelpDefinition: [{
                entity: {
                            name: 'I_SALESDOCUMENTBASIC',
                            element: 'SalesDocument'
                        }
      }]
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
                                name: 'I_SalesDocumentTypeText',
                                element: 'SalesDocumentType'
                            },
                    additionalBinding: [{ localElement: 'DocumentTypeText' ,
                                          element: 'SalesDocumentTypeName',
                                          usage: #FILTER_AND_RESULT },
                                        { localElement:'language',
                                          element: 'Language',
                                          usage: #FILTER_AND_RESULT  }]
      }]
      @EndUserText.label: 'Document Type'
      @ObjectModel.text.element: [ 'DocumentTypeText' ]
      DocumentType,
      DocumentTypeText,
      NetPrice,
      Currency,
      @ObjectModel.text.element: [ 'StatusText' ]
      OverallStatus,
      StatusText,
      OverallStatusCriticality,
      LastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      LastChangedAt,
      language,
      _SalesOrderItem : redirected to composition child ZC_SO_ITEM_RAP


}
