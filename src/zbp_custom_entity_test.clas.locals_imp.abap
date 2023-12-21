CLASS lcl_buffer DEFINITION.
  PUBLIC SECTION.

    "Structure and internal table types for the internal table serving
    "as transactional buffers for the root  entities
    TYPES: BEGIN OF gty_buffer,
             instance TYPE zcustom_entity_test,
             cid      TYPE string,
             changed  TYPE abap_bool,
             deleted  TYPE abap_bool,
           END OF gty_buffer.
    TYPES gtt_buffer TYPE TABLE OF gty_buffer WITH DEFAULT KEY.

    CLASS-DATA:
      "Internal tables serving as transactional buffers for the root entities
      root_buffer TYPE gtt_buffer.

    "Structure and internal table types to include the keys for buffer preparation methods
    TYPES: BEGIN OF root_keys,
             vbeln TYPE zcustom_entity_test-vbeln,
           END OF root_keys,
           tt_root_keys TYPE TABLE OF root_keys WITH DEFAULT KEY.

    "Buffer preparation methods
    CLASS-METHODS: prep_root_buffer IMPORTING keys TYPE tt_root_keys.

ENDCLASS.

CLASS lcl_buffer IMPLEMENTATION.

  METHOD prep_root_buffer.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<buffer>).
      "Logic:
      "- Line with the specific key values exists in the buffer for the root entity
      "- If it is true: Do nothing, buffer is prepared for the specific instance.
      "- Note: If the line is marked as deleted, the buffer should not be filled anew with the data.
      IF line_exists( lcl_buffer=>root_buffer[ instance-vbeln = <buffer>-vbeln ] ).

      ELSE.
        "Checking if entry exists in the database table of the root entity based on the key value
        SELECT SINGLE @abap_true
        FROM zsales_order_rap
        WHERE vbeln = @<buffer>-vbeln
        INTO @DATA(exists).

        IF exists = abap_true.
          "If entry exists, retrieve it based on the shared key value
          DATA line TYPE zcustom_entity_test.
          SELECT SINGLE * FROM zsales_order_rap
              WHERE vbeln = @<buffer>-vbeln
              INTO CORRESPONDING FIELDS OF @line.

          IF sy-subrc = 0.
            "Adding line to the root buffer
            APPEND VALUE #( instance = line ) TO lcl_buffer=>root_buffer.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.




CLASS lhc_SalesOrder DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR SalesOrder RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE SalesOrder.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE SalesOrder.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE SalesOrder.

    METHODS read FOR READ
      IMPORTING keys FOR READ SalesOrder RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK SalesOrder.
    METHODS setStatus FOR MODIFY
      IMPORTING keys FOR ACTION SalesOrder~setStatus RESULT result.

ENDCLASS.

CLASS lhc_SalesOrder IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD create.

    "Preparing the transactional buffer based on the input BDEF derived type.
    lcl_buffer=>prep_root_buffer( CORRESPONDING #( entities ) ).

    "Processing requested entities sequentially
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<create>).
      "Logic:
      "- Line with the specific key does not exist in the buffer for the root entity
      "- Line with the specific key exists in the buffer but it is marked as deleted
      "- If it is true: Add new instance to the buffer and, if needed, remove the instance marked as deleted beforehand
      IF NOT line_exists( lcl_buffer=>root_buffer[ instance-vbeln = <create>-vbeln ] )
      OR line_exists( lcl_buffer=>root_buffer[ instance-vbeln = <create>-vbeln
                                               deleted = abap_true ] ).

        "If it exists, removing instance that is marked for deletion from the transactional buffer since it gets replaced by a new one.
        DELETE lcl_buffer=>root_buffer WHERE instance-vbeln = VALUE #( lcl_buffer=>root_buffer[ instance-vbeln = <create>-vbeln ]-instance-vbeln OPTIONAL ) AND deleted = abap_true.

        "Adding new instance to the transactional buffer by considering %control values
        APPEND VALUE #( cid                = <create>-%cid
                        instance-vbeln     = <create>-vbeln
                        instance-ernam     = COND #( WHEN <create>-%control-ernam NE if_abap_behv=>mk-off
                                                    THEN <create>-ernam )
                        instance-auart    = COND #( WHEN <create>-%control-auart NE if_abap_behv=>mk-off
                                                    THEN <create>-auart )
                        changed            = abap_true
                        deleted            = abap_false ) TO lcl_buffer=>root_buffer.

        "Filling the MAPPED response parameter for the root entity
        INSERT VALUE #( %cid = <create>-%cid
                        %key = <create>-%key ) INTO TABLE mapped-salesorder.

      ELSE.

        "Filling FAILED and REPORTED response parameters
        APPEND VALUE #( %cid        = <create>-%cid
                        %key        = <create>-%key
                        %create     = if_abap_behv=>mk-on
                        %fail-cause = if_abap_behv=>cause-unspecific
                    ) TO failed-salesorder.

        APPEND VALUE #( %cid      = <create>-%cid
                        %key      = <create>-%key
                        %create   = if_abap_behv=>mk-on
                        %msg      = new_message_with_text( severity  = if_abap_behv_message=>severity-error
                                                           text      = 'Create operation failed.' ) ) TO reported-salesorder.

      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD update.

    "Preparing the transactional buffer based on the input BDEF derived type.
    lcl_buffer=>prep_root_buffer( CORRESPONDING #( entities ) ).

    "Processing requested entities sequentially
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<update>).

      "Logic:
      "- Line with the specific key exists in the buffer for the root entity
      "- Line with the specific key must not be marked as deleted
      "- If it is true: Updating the buffer based on the input BDEF derived type and considering %control values
      READ TABLE lcl_buffer=>root_buffer WITH KEY instance-vbeln = <update>-vbeln deleted = abap_false ASSIGNING FIELD-SYMBOL(<fs_up>).

      IF sy-subrc = 0.
        <fs_up>-instance-ernam  = COND #( WHEN <update>-%control-ernam NE if_abap_behv=>mk-off
                                            THEN <update>-ernam
                                            ELSE <fs_up>-instance-ernam ).

        <fs_up>-instance-auart  = COND #( WHEN <update>-%control-auart NE if_abap_behv=>mk-off
                                            THEN <update>-auart
                                            ELSE <fs_up>-instance-auart ).

        <fs_up>-changed  = abap_true.
        <fs_up>-deleted  = abap_false.


      ELSE.

        "Filling FAILED and REPORTED response parameters
        APPEND VALUE #( %tky         = <update>-%tky
                        %cid         = <update>-%cid_ref
                        %fail-cause  = if_abap_behv=>cause-not_found
                        %update      = if_abap_behv=>mk-on
                    ) TO failed-salesorder.

        APPEND VALUE #( %tky = <update>-%tky
                        %cid = <update>-%cid_ref
                        %msg = new_message_with_text( severity  = if_abap_behv_message=>severity-error
                                                      text      = 'Update operation failed.' ) ) TO reported-salesorder.

      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD delete.
  ENDMETHOD.

  METHOD read.

    "Preparing the transactional buffer based on the input BDEF derived type.
    lcl_buffer=>prep_root_buffer( CORRESPONDING #( keys ) ).

    "Processing requested keys sequentially
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<read>) GROUP BY <read>-%tky.
      "Logic:
      "- Line exists in the buffer and it is not marked as deleted
      "- If it is true: Adding the entries to the buffer based on the input BDEF derived type and considering %control values
      READ TABLE lcl_buffer=>root_buffer WITH KEY instance-vbeln = <read>-vbeln deleted = abap_false ASSIGNING FIELD-SYMBOL(<fs_r>).

      IF sy-subrc = 0.

        APPEND VALUE #( %tky   = <read>-%tky
                        ernam = COND #( WHEN <read>-%control-ernam NE if_abap_behv=>mk-off
                                        THEN <fs_r>-instance-ernam )
                        auart = COND #( WHEN <read>-%control-auart NE if_abap_behv=>mk-off
                                          THEN <fs_r>-instance-auart ) ) TO result.

      ELSE.

        "Filling FAILED and REPORTED response parameters
        APPEND VALUE #( %tky         = <read>-%tky
                        %fail-cause  = if_abap_behv=>cause-not_found ) TO failed-salesorder.

        APPEND VALUE #( %tky = <read>-%tky
                        %msg = new_message_with_text( severity  = if_abap_behv_message=>severity-error
                                                      text      = 'Read operation failed.' ) ) TO reported-salesorder.

      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD setStatus.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZCUSTOM_ENTITY_TEST DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZCUSTOM_ENTITY_TEST IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.

    "Processing the saving of create and update operations
    "Only those entries should be saved to the database table whose flag for "changed" is not initial.
    DATA mod_tab TYPE TABLE OF zcustom_entity_test.

    IF line_exists( lcl_buffer=>root_buffer[ changed = abap_true ] ).
      LOOP AT lcl_buffer=>root_buffer ASSIGNING FIELD-SYMBOL(<cr>) WHERE changed = abap_true AND deleted = abap_false.

        APPEND CORRESPONDING #( <cr>-instance ) TO mod_tab.

      ENDLOOP.

      MODIFY zsales_order_rap FROM TABLE @( CORRESPONDING #( mod_tab MAPPING uvall = OverallStatus ) ).
      WAIT UP TO 10 SECONDS.
    ENDIF.

    "Processing the saving of delete operations
    "Only those entries should be deleted from the database table whose flag "deleted" is not initial.
    DATA del_tab TYPE lcl_buffer=>tt_root_keys.

    IF line_exists( lcl_buffer=>root_buffer[ deleted = abap_true ] ).

      LOOP AT lcl_buffer=>root_buffer ASSIGNING FIELD-SYMBOL(<del>) WHERE deleted = abap_true.

        APPEND CORRESPONDING #( <del>-instance ) TO del_tab.

      ENDLOOP.

      DELETE zsales_order_rap FROM TABLE @( CORRESPONDING #( del_tab ) ).
    ENDIF.

  ENDMETHOD.

  METHOD cleanup.
    "Clearing the transactional buffer.
    CLEAR lcl_buffer=>root_buffer.
  ENDMETHOD.

  METHOD cleanup_finalize.
    "Clearing the transactional buffer.
    CLEAR lcl_buffer=>root_buffer.
  ENDMETHOD.

ENDCLASS.
