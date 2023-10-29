CLASS lhc_salesorder DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR salesorder RESULT result.

*    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
*      IMPORTING REQUEST requested_authorizations FOR salesorder RESULT result.

    METHODS setprocessed FOR MODIFY
      IMPORTING keys FOR ACTION salesorder~setprocessed RESULT result.

    METHODS settotalprice_action FOR MODIFY
      IMPORTING keys FOR ACTION salesorder~settotalprice_action RESULT result.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST request FOR salesorder RESULT result.

    METHODS validatesalesorder FOR VALIDATE ON SAVE
      IMPORTING keys FOR salesorder~validatesalesorder.

    METHODS setcreateddate_by FOR DETERMINE ON MODIFY
      IMPORTING keys FOR salesorder~setcreateddate_by.

    METHODS settotalprice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR salesorderitem~settotalprice.

    METHODS precheck_create FOR PRECHECK
      IMPORTING entities FOR CREATE salesorder.

ENDCLASS.

CLASS lhc_salesorder IMPLEMENTATION.

  METHOD setprocessed.

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
                         %msg = new_message_with_text(  text = 'Sales Order cannot be less than 300' ) ) TO reported-salesorder.

      ELSEIF <nfs_sales_order>-documenttype ='YNBO' AND
             <nfs_sales_order>-salesorder > 1000.

        APPEND VALUE #(  %tky = <nfs_sales_order>-%tky ) TO failed-salesorder.
        APPEND VALUE #(  %tky = <nfs_sales_order>-%tky
                         %msg = new_message_with_text(  text = 'Sales Order cannot be greater than 1000 for Document type-YNBO' ) ) TO reported-salesorder.

      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD setcreateddate_by.

    MODIFY ENTITIES OF zi_sales_order_rap IN LOCAL MODE
        ENTITY salesorder
            UPDATE FIELDS (  createdby creationdate )
            WITH VALUE #( FOR ls_key IN keys ( %tky = ls_key-%tky
*                                               createdby = sy-uname
                                               creationdate = sy-datum ) ).

  ENDMETHOD.

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

*  METHOD get_global_authorizations.
*
*    IF requested_authorizations-%update = if_abap_behv=>mk-on OR
*       requested_authorizations-%action-edit = if_abap_behv=>mk-on.
*
*      "Check if authorized
*      IF 1 = 2.
*      ELSE.
*        result-%update = if_abap_behv=>auth-unauthorized.
*        result-%action-edit = if_abap_behv=>auth-unauthorized.
*      ENDIF.
*
*    ENDIF.
*  ENDMETHOD.

  METHOD get_instance_authorizations.

  ENDMETHOD.

ENDCLASS.
