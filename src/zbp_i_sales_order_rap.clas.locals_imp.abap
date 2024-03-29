CLASS lhc_salesorder DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS setprocessed FOR MODIFY
      IMPORTING keys FOR ACTION salesorder~setprocessed RESULT result.

    METHODS settotalprice_action FOR MODIFY
      IMPORTING keys FOR ACTION salesorder~settotalprice_action RESULT result.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST request FOR salesorder RESULT result.

    METHODS validatesalesorder FOR VALIDATE ON SAVE
      IMPORTING keys FOR salesorder~validatesalesorder.

*    METHODS set_language FOR DETERMINE ON MODIFY
*      IMPORTING keys FOR salesorder~setLanguage.

    METHODS settotalprice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR salesorderitem~settotalprice.

    METHODS precheck_create FOR PRECHECK
      IMPORTING entities FOR CREATE salesorder.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR salesorder RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR salesorder RESULT result.

    METHODS copysalesorder FOR MODIFY
      IMPORTING keys FOR ACTION salesorder~copysalesorder.

    METHODS createinstance FOR MODIFY
      IMPORTING keys FOR ACTION salesorder~createinstance.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE salesorder.

ENDCLASS.

CLASS lhc_salesorder IMPLEMENTATION.

  METHOD setprocessed.

    "1. Using UI.lineitem.invocationGrouping: #change_set
    "   a single call to the action will be made with all selected line items
    "   If there is any validation failures, and failed and reported structures are filled then none of the records are updated.
    "   If we don't fill the failed and reported structures then the successful instances will be updated.

    "2. Using UI.lineitem.invocationGrouping: #isolated (default)
    "   multiple calls will be made to the action method with single instance key
    "   For the instances in error( and for which failed and reported structures are filled), error messages will be shown
    "   Rest will be successfully updated

    "Below commentd line is to demonstrate point 1.
*    LOOP AT keys ASSIGNING FIELD-SYMBOL(<nfs_key>).
*      IF <nfs_key>-SalesOrder >= 700.
*
*        APPEND VALUE #( %tky = <nfs_key>-%tky ) TO failed-salesorder.
*        APPEND VALUE #( %tky = <nfs_key>-%tky
*                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-warning
*                                                      text = 'Failed to Set Status') ) TO reported-salesorder.
*      ELSE.
*        MODIFY ENTITIES OF zi_sales_order_rap IN LOCAL MODE
*            ENTITY SalesOrder
*            UPDATE FIELDS ( OverallStatus ) WITH VALUE #( ( %tky = <nfs_key>-%tky
*                                                            OverallStatus = 'C' ) ).
*      ENDIF.
*    ENDLOOP.


    MODIFY ENTITIES OF zi_sales_order_rap IN LOCAL MODE
    ENTITY salesorder
    UPDATE FIELDS ( overallstatus )
    WITH VALUE #(  FOR ls_key IN keys (  %tky = ls_key-%tky  overallstatus = 'C' ) )
    FAILED failed
    REPORTED reported.

    "Get the Result updated
    READ ENTITIES OF zi_sales_order_rap IN LOCAL MODE
        ENTITY salesorder
            ALL FIELDS WITH CORRESPONDING #( keys )
            RESULT DATA(nt_sales_order).

    result = VALUE #( FOR ls_sales_order IN nt_sales_order ( %tky = ls_sales_order-%tky

                                                             %param = CORRESPONDING #(  ls_sales_order ) ) ).
  ENDMETHOD.

  METHOD get_instance_features.

    READ ENTITIES OF zi_sales_order_rap IN LOCAL MODE
        ENTITY salesorder
            ALL FIELDS WITH CORRESPONDING #(  keys )
            RESULT DATA(nt_sale_sorder)
            FAILED DATA(ns_failed)
            REPORTED DATA(ns_reported).

    result = VALUE #(  FOR ls_sales_order IN nt_sale_sorder
                           (  %tky = ls_sales_order-%tky
                              %features-%action-setprocessed = COND #(  WHEN ls_sales_order-overallstatus = 'C' THEN if_abap_behv=>fc-o-disabled
                                                                        ELSE if_abap_behv=>fc-o-enabled )
                              %field-documentcategory = COND #(  WHEN ls_sales_order-documentcategory IS INITIAL THEN if_abap_behv=>fc-f-unrestricted
                                                             ELSE if_abap_behv=>fc-f-read_only ) ) ).

  ENDMETHOD.

  METHOD validatesalesorder.

    READ ENTITIES OF zi_sales_order_rap IN LOCAL MODE
        ENTITY salesorder FIELDS ( salesorder ) WITH CORRESPONDING #( keys )
        RESULT DATA(nt_salesorder).

    LOOP AT nt_salesorder ASSIGNING FIELD-SYMBOL(<nfs_sales_order>).
      IF <nfs_sales_order>-salesorder < 300.
        APPEND VALUE #(  %tky = <nfs_sales_order>-%tky ) TO failed-salesorder.
        APPEND VALUE #(  %tky = <nfs_sales_order>-%tky
                         %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                       text = 'Sales Order cannot be less than 300' ) ) TO reported-salesorder.

      ELSEIF <nfs_sales_order>-documenttype ='YNBO' AND
             <nfs_sales_order>-salesorder > 1000.

        APPEND VALUE #(  %tky = <nfs_sales_order>-%tky ) TO failed-salesorder.
        APPEND VALUE #(  %tky = <nfs_sales_order>-%tky
                         %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                       text = 'Sales Order cannot be greater than 1000 for Document type-YNBO' ) ) TO reported-salesorder.

      ENDIF.
    ENDLOOP.
  ENDMETHOD.

*  METHOD set_language.
*    TRY.
*        MODIFY ENTITIES OF zi_sales_order_rap IN LOCAL MODE
*            ENTITY salesorder
*                UPDATE FIELDS (  createdby creationdate language )
*                WITH VALUE #( FOR ls_key IN keys ( %tky = ls_key-%tky
*                                                   language = cl_abap_context_info=>get_user_language_abap_format(  ) ) ).
*      CATCH cx_abap_context_info_error.
*    ENDTRY.
*  ENDMETHOD.

  METHOD settotalprice.

*Header net price can be set either by using
*1. Determination on child entity
*2. Using Internal Actions

**********************Option 1************************************
*    READ ENTITIES OF zi_sales_order_rap IN LOCAL MODE
*        ENTITY salesorderitem BY \_salesorderheader
*        FIELDS ( netprice )
*        WITH CORRESPONDING #( keys )
*        RESULT DATA(nt_sales_order).
*
*    READ ENTITIES OF zi_sales_order_rap IN LOCAL MODE
*        ENTITY salesorder BY \_salesorderitem
*        FIELDS (  targetquantity itemamount )
*        WITH CORRESPONDING #( nt_sales_order )
*        RESULT DATA(nt_items).
*
*    DATA: nv_total_price TYPE p LENGTH 16 DECIMALS 2.
*
*    LOOP AT nt_sales_order ASSIGNING FIELD-SYMBOL(<nfs_sales_order>).
*
*      LOOP AT nt_items ASSIGNING FIELD-SYMBOL(<nfs_item>) USING KEY entity WHERE salesorder  = <nfs_sales_order>-salesorder.
*        nv_total_price += ( <nfs_item>-targetquantity * <nfs_item>-itemamount ).
*        DATA(nv_item_currency) = <nfs_item>-currency.
*      ENDLOOP.
*
*      <nfs_sales_order>-netprice = nv_total_price.
*      <nfs_sales_order>-currency = nv_item_currency.
*
*      CLEAR: nv_total_price,
*             nv_item_currency.
*    ENDLOOP.
*
*
*    MODIFY ENTITIES OF zi_sales_order_rap IN LOCAL MODE
*        ENTITY salesorder
*        UPDATE FIELDS ( netprice currency )
*        WITH CORRESPONDING #( nt_sales_order ).


**********************Option 2************************************

    READ ENTITIES OF zi_sales_order_rap IN LOCAL MODE
        ENTITY salesorderitem BY \_salesorderheader
        FIELDS ( netprice )
        WITH CORRESPONDING #( keys )
        RESULT DATA(nt_sales_order).


    MODIFY ENTITIES OF zi_sales_order_rap IN LOCAL MODE
        ENTITY salesorder
        EXECUTE settotalprice_action FROM CORRESPONDING #( nt_sales_order ).

  ENDMETHOD.



  METHOD settotalprice_action.

    READ ENTITIES OF zi_sales_order_rap IN LOCAL MODE
        ENTITY salesorder
        FIELDS ( netprice )
        WITH CORRESPONDING #( keys )
        RESULT DATA(nt_sales_order).

    READ ENTITIES OF zi_sales_order_rap IN LOCAL MODE
        ENTITY salesorder BY \_salesorderitem
        FIELDS (  targetquantity itemamount )
        WITH CORRESPONDING #( nt_sales_order )
        RESULT DATA(nt_items).

    DATA: nv_total_price TYPE p LENGTH 16 DECIMALS 2.

    LOOP AT nt_sales_order ASSIGNING FIELD-SYMBOL(<nfs_sales_order>).

      LOOP AT nt_items ASSIGNING FIELD-SYMBOL(<nfs_item>) USING KEY entity WHERE salesorder  = <nfs_sales_order>-salesorder.
        nv_total_price += ( <nfs_item>-targetquantity * <nfs_item>-itemamount ).
        DATA(nv_item_currency) = <nfs_item>-currency.
      ENDLOOP.

      <nfs_sales_order>-netprice = nv_total_price.
      <nfs_sales_order>-currency = nv_item_currency.

      CLEAR: nv_total_price,
             nv_item_currency.
    ENDLOOP.

    MODIFY ENTITIES OF zi_sales_order_rap IN LOCAL MODE
        ENTITY salesorder
        UPDATE FIELDS ( netprice currency )
        WITH CORRESPONDING #( nt_sales_order ).


    "Get the Result updated
    READ ENTITIES OF zi_sales_order_rap IN LOCAL MODE
        ENTITY salesorder
            ALL FIELDS WITH CORRESPONDING #( keys )
            RESULT DATA(nt_sales_order_update).

    result = VALUE #( FOR ls_sales_order IN nt_sales_order_update ( %tky = ls_sales_order-%tky
                                                                    %param = CORRESPONDING #(  ls_sales_order ) ) ).
  ENDMETHOD.

  METHOD precheck_create.
    "uniqueness check for Sales order

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<nfs_entity>).

      CHECK <nfs_entity>-%control-salesorder = if_abap_behv=>mk-on.

      READ ENTITIES OF zi_sales_order_rap IN LOCAL MODE
        ENTITY salesorder ALL FIELDS WITH VALUE #( ( %key = <nfs_entity>-%key ) )
        RESULT DATA(nt_sales_order_db).

      IF nt_sales_order_db IS NOT INITIAL.
        "Error
        APPEND VALUE #( %key = <nfs_entity>-%key ) TO failed-salesorder.

        APPEND VALUE #(  %key = <nfs_entity>-%key
*                         %state_area = 'PreCheck'
                         %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                       text = 'Sales Order Already Exists.' )
                         %element-salesorder = if_abap_behv=>mk-on ) TO reported-salesorder.
      ELSE.
        "Message Toast is displayed
        APPEND VALUE #(  %key = <nfs_entity>-%key
*                         %state_area = 'PreCheck'
                         %msg = new_message_with_text( severity = if_abap_behv_message=>severity-success
                                                       text = 'Sales Order Created. Precheck Successful' )
                         %element-salesorder = if_abap_behv=>mk-on ) TO reported-salesorder.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD get_global_authorizations.

    "setting the result as unauthorized will make the buttons disappear.

    IF requested_authorizations-%update = if_abap_behv=>mk-on OR
       requested_authorizations-%create = if_abap_behv=>mk-on OR
       requested_authorizations-%action-edit = if_abap_behv=>mk-on.


      "Check if authorized
      IF 1 = 1.
      ELSE.
        result-%update = if_abap_behv=>auth-unauthorized.
        result-%action-edit = if_abap_behv=>auth-unauthorized.
      ENDIF.

    ENDIF.
  ENDMETHOD.

  METHOD get_instance_authorizations.
    "1. if we use the BO addition authorization:update, then %action-setProcesses will not be present in requested and result parameter
    " The button will be visible
    "with this we can check authorization at the time of pressing the action button( %update will be set ) and then show authorization error

    "2. In case we want to make the button disappear w.r.t entity instance then simply adding authorization master( instance ) in the entity def is enough
    "and then making the result-%action-setProcessed to unauthorized value.

    READ ENTITIES OF zi_sales_order_rap IN LOCAL MODE
      ENTITY SalesOrder ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(nt_sales_order).

    LOOP AT nt_sales_order ASSIGNING FIELD-SYMBOL(<nfs_sales_order>).
      IF requested_authorizations-%action-setProcessed = if_abap_behv=>mk-on AND
         <nfs_sales_order>-OverallStatus = 'A' AND
         <nfs_sales_order>-SalesOrder = '500'.

        APPEND VALUE #(  %tky = <nfs_sales_order>-%tky
                         %action-setprocessed = if_abap_behv=>auth-unauthorized ) TO result.

        "Displaying error will only be relevant for point 1.
*        APPEND VALUE #( %tky = <nfs_sales_order>-%tky ) TO failed-salesorder.
*
*        APPEND VALUE #(  %tky = <nfs_sales_order>-%tky
**                         %state_area = 'PreCheck'
*                         %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
*                                                       text = 'No Authorization to process Status' ) ) TO reported-salesorder.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD copySalesOrder.

    DATA: lt_sales_order TYPE TABLE FOR CREATE zi_sales_order_rap\\SalesOrder.

    READ ENTITIES OF zi_sales_order_rap IN LOCAL MODE
      ENTITY SalesOrder
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(nt_sales_order).

    LOOP AT nt_sales_order ASSIGNING FIELD-SYMBOL(<nfs_salses_order>).
      lt_sales_order = VALUE #(  BASE lt_sales_order ( %cid = VALUE #(  keys[ KEY entity SalesOrder = <nfs_salses_order>-SalesOrder ]-%cid OPTIONAL )
                                                       %is_draft = '01'
                                                       %data = CORRESPONDING #( <nfs_salses_order> ) ) ).
*                                                       %key-SalesOrder = zcreate_num_range_object=>get_sales_order_num(  ) ) ).
    ENDLOOP.

    "Sales order can be passed in which case in early numbering method, assignment of new SO id is skipped
    MODIFY ENTITIES OF zi_sales_order_rap IN LOCAL MODE
        ENTITY SalesOrder
        CREATE FIELDS ( DocumentCategory DocumentType
*        DocumentTypeText
                        OverallStatus NetPrice Currency StatusText
                        OverallStatusCriticality TransactionGroup ) WITH lt_sales_order
        MAPPED DATA(mapped_new).

    mapped-salesorder = mapped_new-salesorder.

  ENDMETHOD.

  METHOD CreateInstance.
    "Sales order can be passed in which case in early numbering method, assignment of new SO id is skipped
    MODIFY ENTITIES OF zi_sales_order_rap IN LOCAL MODE
      ENTITY SalesOrder
      CREATE FIELDS ( DocumentType DocumentCategory
*      DocumentTypeText
      TransactionGroup OverallStatus )
      WITH VALUE #( FOR ls_key IN keys ( %cid = ls_key-%cid
                                         %is_draft = if_abap_behv=>mk-on
*                                         SalesOrder = zcreate_num_range_object=>get_sales_order_num(  )
                                         DocumentType = 'YNRE'
*                                         DocumentTypeText = 'Return Order'
                                         DocumentCategory = 'C'
                                         OverallStatus = 'A' ) )
      MAPPED mapped
      REPORTED reported
      FAILED failed.

  ENDMETHOD.

  METHOD earlynumbering_create.

    " Ensure Sales order is not set yet (idempotent)- must be checked when BO is draft-enabled
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<nfs_entity>).
      IF <nfs_entity>-SalesOrder IS NOT INITIAL.
        APPEND CORRESPONDING #( <nfs_entity> ) TO mapped-salesorder.
      ELSE.
        DATA(nv_entity_wo_sales_order) = <nfs_entity>.
        nv_entity_wo_sales_order-SalesOrder = zcreate_num_range_object=>get_sales_order_num(  ).
        APPEND CORRESPONDING #( nv_entity_wo_sales_order ) TO mapped-salesorder.


      ENDIF.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.


CLASS lsc_zi_sales_order_rap DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_zi_sales_order_rap IMPLEMENTATION.

  METHOD save_modified.

  data(creates) =  create-salesorder.
  data(updates) = update-salesorder.

  ENDMETHOD.

ENDCLASS.
