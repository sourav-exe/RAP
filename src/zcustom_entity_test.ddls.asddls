@EndUserText.label: 'Custom Entity'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_CUSTOM_ENTITY_IMPL'
define root custom entity ZCUSTOM_ENTITY_TEST
{

      @UI.facet         : [{
          id            : 'HeadInfo',
          purpose       : #STANDARD,
          position      : 10 ,
          label         : 'General Info',
          type          : #IDENTIFICATION_REFERENCE,
          targetQualifier: 'GENINFO'
      }]
      @UI.lineItem      : [{ position: 10, label: 'Sales Order No.' }]
      @UI.identification: [{ qualifier: 'GENINFO', position: 10 , type: #STANDARD, label: 'Sales Order' }]
      @UI.selectionField: [{ position: 10 }]
      @EndUserText.label: 'Sales Order'
  key vbeln             : abap.char( 10 );

      @UI.lineItem      : [{ position: 20, label: 'Created By' }]
      @UI.identification: [{ qualifier: 'GENINFO', position: 20 , type: #STANDARD, label: 'Created By User' }]
      @UI.selectionField: [{ position: 20 }]
      @EndUserText.label: 'Created By'
      @Semantics.user.createdBy: true
      ERNAM             : abap.char( 10 );

      @UI.lineItem      : [{ position: 30, label: 'Order Type' }]
      @UI.identification: [{ qualifier: 'GENINFO', position: 30 , type: #STANDARD, label: 'Order Type' }]
      auart             : abap.char(4);

      @UI.lineItem      : [{ position: 40, label: 'Statusjj', criticality: 'StatusCriticality' },
                           { type: #FOR_ACTION, dataAction: 'setStatus', label: 'Set Status' }]
      @UI.identification: [{ qualifier: 'GENINFO', position: 40 , type: #STANDARD, label: 'Status', criticality: 'StatusCriticality' },
                           { type: #FOR_ACTION, dataAction: 'setStatus', label: 'Set Status' }]
      @UI.textArrangement: #TEXT_ONLY
      @ObjectModel.text.element: [ 'StatusText' ]
      OverallStatus     : abap.char(1);

      @UI.hidden        : true
      StatusText        : abap.char(20);

      @UI.hidden        : true
      StatusCriticality : abap.numc( 1 );

}
