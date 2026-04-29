# IM Flutter 目录树与文件清单 v1.0

> 文档日期：2026-04-29  
> 文档定位：Flutter `lib/` 级目录树、feature 级文件清单、首批建议创建文件  

---

## 1. 目标

本文件直接回答两个问题：

1. Flutter 工程最终目录树应该长什么样
2. 第一阶段应该先创建哪些文件

---

## 2. `lib/` 总目录树

```text
lib/
  main.dart
  app/
    bootstrap/
      app_bootstrap.dart
      auth_bootstrap_coordinator.dart
      app_bootstrap_provider.dart
    router/
      app_router.dart
      route_names.dart
      route_paths.dart
      route_guards.dart
      route_args/
        chat_entry_args.dart
        group_context_args.dart
        user_profile_args.dart
        file_preview_args.dart
        call_launch_args.dart
    shell/
      app_shell.dart
      shell_tab_item.dart
    theme/
      app_theme.dart
      app_colors.dart
      app_spacing.dart
      app_radius.dart
      app_typography.dart
      theme_mode_controller.dart
    l10n/
      app_locale_controller.dart
      l10n_keys.dart
  core/
    auth/
      auth_session.dart
      auth_session_provider.dart
      refresh_token_coordinator.dart
      token_storage.dart
    network/
      dio_client.dart
      api_result.dart
      api_exception.dart
      interceptors/
        auth_interceptor.dart
        tenant_interceptor.dart
        locale_interceptor.dart
        request_id_interceptor.dart
    websocket/
      im_socket_client.dart
      socket_state.dart
      socket_event.dart
      socket_codec.dart
      socket_message_dispatcher.dart
    storage/
      secure_storage_service.dart
      kv_storage_service.dart
      storage_key_registry.dart
    platform/
      platform_capabilities.dart
      file_picker_service.dart
      image_picker_service.dart
      recorder_service.dart
      audio_player_service.dart
      video_player_service.dart
      qr_scanner_service.dart
      app_visibility_service.dart
      push/
        push_facade.dart
        push_provider.dart
        push_message.dart
        push_token.dart
      map/
        map_facade.dart
        map_provider.dart
        map_models.dart
      rtc/
        rtc_facade.dart
        rtc_gateway.dart
    logging/
      app_logger.dart
      log_category.dart
    error/
      app_error.dart
      app_error_mapper.dart
  features/
    login/
      ...
    im/
      conversation/
        ...
      chat/
        ...
      call/
        ...
      group/
        ...
      contact/
        ...
      search/
        ...
      favorite/
        ...
      receipt/
        ...
      media/
        ...
    profile/
      ...
    workbench/
      ...
  shared/
    widgets/
      app_avatar.dart
      app_badge.dart
      app_empty_view.dart
      app_error_view.dart
      app_loading_view.dart
      app_search_bar.dart
      app_section_tile.dart
      app_danger_tile.dart
    layout/
      adaptive_scaffold.dart
      adaptive_two_pane.dart
    extensions/
      string_extensions.dart
      datetime_extensions.dart
    constants/
      app_constants.dart
    enums/
      conversation_type.dart
      message_type.dart
      message_status.dart
      group_member_role.dart
```

---

## 3. Feature 目录模板

每个 feature 统一采用：

```text
feature_name/
  presentation/
    pages/
    controllers/
    states/
    widgets/
    providers/
    mappers/
  application/
    usecases/
    commands/
    results/
    coordinators/
    policies/
  domain/
    entities/
    value_objects/
    repositories/
    services/
    enums/
  infrastructure/
    datasources/
    dtos/
    mappers/
    repositories/
    adapters/
```

---

## 4. `conversation` 文件清单

```text
features/im/conversation/
  presentation/
    pages/
      conversation_list_page.dart
    controllers/
      conversation_list_controller.dart
    states/
      conversation_list_state.dart
      conversation_filter_state.dart
    widgets/
      conversation_header.dart
      conversation_tile.dart
      pinned_conversation_section.dart
      conversation_context_menu.dart
    providers/
      conversation_providers.dart
    mappers/
      conversation_ui_model_mapper.dart
  application/
    usecases/
      load_conversation_list_use_case.dart
      refresh_conversation_list_use_case.dart
      sync_conversations_incrementally_use_case.dart
      pin_conversation_use_case.dart
      toggle_conversation_no_disturb_use_case.dart
      delete_conversation_use_case.dart
      open_or_create_conversation_use_case.dart
    commands/
      sync_conversations_command.dart
    results/
      conversation_sync_result.dart
    coordinators/
      conversation_sync_coordinator.dart
    policies/
      conversation_sort_policy.dart
  domain/
    entities/
      conversation.dart
      conversation_cursor_state.dart
    repositories/
      conversation_repository.dart
    enums/
      conversation_filter_type.dart
  infrastructure/
    datasources/
      conversation_remote_data_source.dart
      conversation_local_data_source.dart
    dtos/
      conversation_dto.dart
      conversation_sync_response_dto.dart
      conversation_preference_request_dto.dart
    mappers/
      conversation_dto_mapper.dart
      conversation_record_mapper.dart
    repositories/
      conversation_repository_impl.dart
```

---

## 5. `chat` 文件清单

```text
features/im/chat/
  presentation/
    pages/
      chat_page.dart
      direct_chat_settings_page.dart
      chat_history_search_page.dart
      forward_target_picker_page.dart
      merged_forward_detail_page.dart
      mention_picker_page.dart
      contact_card_picker_page.dart
      location_picker_page.dart
      video_player_page.dart
      file_preview_page.dart
    controllers/
      chat_controller.dart
      chat_timeline_controller.dart
      chat_composer_controller.dart
      chat_media_controller.dart
      chat_receipt_controller.dart
      chat_viewport_controller.dart
      direct_chat_settings_controller.dart
      chat_history_search_controller.dart
      forward_target_picker_controller.dart
    states/
      chat_page_state.dart
      chat_timeline_state.dart
      chat_composer_state.dart
      chat_receipt_state.dart
      direct_chat_settings_state.dart
    widgets/
      chat_app_bar.dart
      chat_notice_banner.dart
      chat_timeline.dart
      chat_message_item.dart
      chat_composer.dart
      chat_more_panel.dart
      chat_action_sheet.dart
      chat_read_receipt_sheet.dart
      message_bubbles/
        text_message_bubble.dart
        image_message_bubble.dart
        video_message_bubble.dart
        voice_message_bubble.dart
        file_message_bubble.dart
        location_message_bubble.dart
        contact_card_bubble.dart
        sticker_message_bubble.dart
        quote_reply_message_bubble.dart
        merged_forward_bubble.dart
        system_tip_bubble.dart
      factories/
        message_bubble_factory.dart
    providers/
      chat_providers.dart
    mappers/
      message_ui_model_mapper.dart
  application/
    usecases/
      open_chat_use_case.dart
      load_chat_window_use_case.dart
      load_older_messages_use_case.dart
      locate_message_use_case.dart
      restore_viewport_use_case.dart
      persist_viewport_use_case.dart
      send_message_use_case.dart
      recall_message_use_case.dart
      delete_message_use_case.dart
      forward_messages_use_case.dart
      add_favorite_use_case.dart
      mark_conversation_read_use_case.dart
      sync_voice_played_use_case.dart
      pull_messages_after_reconnect_use_case.dart
    commands/
      open_chat_command.dart
      load_chat_window_command.dart
      locate_message_command.dart
      send_message_command.dart
      forward_messages_command.dart
      mark_conversation_read_command.dart
    results/
      open_chat_result.dart
      chat_window_result.dart
      locate_message_result.dart
      send_message_result.dart
    coordinators/
      chat_upload_coordinator.dart
      audio_playback_coordinator.dart
      file_open_coordinator.dart
    policies/
      message_merge_policy.dart
      chat_entry_policy.dart
  domain/
    entities/
      message.dart
      message_extra.dart
      quote_info.dart
      chat_viewport_state.dart
    value_objects/
      message_body/
        text_message_body.dart
        image_message_body.dart
        voice_message_body.dart
        video_message_body.dart
        file_message_body.dart
        location_message_body.dart
        contact_card_message_body.dart
        merged_forward_body.dart
    repositories/
      message_repository.dart
      file_repository.dart
      favorite_repository.dart
    enums/
      chat_entry_mode.dart
  infrastructure/
    datasources/
      message_remote_data_source.dart
      message_local_data_source.dart
      favorite_remote_data_source.dart
      file_remote_data_source.dart
    dtos/
      message_dto.dart
      message_window_response_dto.dart
      message_history_response_dto.dart
      send_message_request_dto.dart
      forward_messages_request_dto.dart
    mappers/
      message_dto_mapper.dart
      message_record_mapper.dart
    repositories/
      message_repository_impl.dart
      file_repository_impl.dart
      favorite_repository_impl.dart
```

---

## 6. `group` 文件清单

```text
features/im/group/
  presentation/
    pages/
      group_settings_page.dart
      group_members_page.dart
      group_join_requests_page.dart
      group_notice_page.dart
      group_invite_page.dart
      join_group_page.dart
    controllers/
      group_settings_controller.dart
      group_members_controller.dart
      group_join_requests_controller.dart
      group_notice_controller.dart
      group_invite_controller.dart
      join_group_controller.dart
    states/
      group_settings_state.dart
      group_members_state.dart
      group_join_requests_state.dart
      group_notice_state.dart
    widgets/
      group_overview_section.dart
      group_members_preview_section.dart
      group_governance_section.dart
      group_danger_zone_section.dart
    providers/
      group_providers.dart
  application/
    usecases/
      load_group_settings_use_case.dart
      load_group_members_use_case.dart
      update_group_name_use_case.dart
      update_group_preference_use_case.dart
      set_group_member_role_use_case.dart
      remove_group_member_use_case.dart
      transfer_group_owner_use_case.dart
      quit_group_use_case.dart
      dissolve_group_use_case.dart
      load_group_join_requests_use_case.dart
      approve_group_join_request_use_case.dart
      reject_group_join_request_use_case.dart
      update_group_notice_use_case.dart
    commands/
      update_group_preference_command.dart
      transfer_group_owner_command.dart
    results/
      group_settings_result.dart
    coordinators/
      group_lifecycle_action_coordinator.dart
  domain/
    entities/
      group_info.dart
      group_member.dart
      group_join_request.dart
    repositories/
      group_repository.dart
    enums/
      group_join_request_status.dart
  infrastructure/
    datasources/
      group_remote_data_source.dart
      group_local_data_source.dart
    dtos/
      group_info_dto.dart
      group_member_dto.dart
      group_join_request_dto.dart
    mappers/
      group_dto_mapper.dart
    repositories/
      group_repository_impl.dart
```

---

## 7. `contact` 文件清单

```text
features/im/contact/
  presentation/
    pages/
      contacts_home_page.dart
      org_browser_page.dart
      create_group_page.dart
      user_profile_page.dart
      my_groups_page.dart
      star_contacts_page.dart
      my_department_page.dart
    controllers/
      contacts_home_controller.dart
      org_browser_controller.dart
      create_group_controller.dart
      user_profile_controller.dart
      my_groups_controller.dart
      star_contacts_controller.dart
      my_department_controller.dart
    states/
      contacts_home_state.dart
      org_browser_state.dart
      create_group_state.dart
      user_profile_state.dart
    widgets/
      contacts_quick_entry_section.dart
      contacts_alphabet_list_section.dart
      org_tree_panel.dart
      dept_members_panel.dart
    providers/
      contact_providers.dart
  application/
    usecases/
      load_contacts_home_use_case.dart
      load_org_tree_use_case.dart
      load_dept_members_use_case.dart
      load_user_profile_use_case.dart
      toggle_star_contact_use_case.dart
      create_group_use_case.dart
    results/
      contacts_home_result.dart
  domain/
    entities/
      contact.dart
      dept_node.dart
    repositories/
      contact_repository.dart
  infrastructure/
    datasources/
      contact_remote_data_source.dart
      contact_local_data_source.dart
    dtos/
      contact_dto.dart
      dept_node_dto.dart
    mappers/
      contact_dto_mapper.dart
    repositories/
      contact_repository_impl.dart
```

---

## 8. `search` / `favorite` / `receipt` / `media` 文件清单

### 8.1 search

```text
features/im/search/
  presentation/
    pages/
      global_search_page.dart
    controllers/
      global_search_controller.dart
    states/
      global_search_state.dart
    widgets/
      search_history_section.dart
      hot_search_section.dart
      search_results_section.dart
    providers/
      search_providers.dart
  application/
    usecases/
      load_hot_search_use_case.dart
      search_global_use_case.dart
      load_search_history_use_case.dart
      persist_search_history_use_case.dart
    commands/
      search_global_command.dart
    results/
      global_search_result.dart
  domain/
    entities/
      global_search_item.dart
    repositories/
      search_repository.dart
  infrastructure/
    datasources/
      search_remote_data_source.dart
      search_local_data_source.dart
    dtos/
      global_search_item_dto.dart
      global_search_response_dto.dart
    mappers/
      search_dto_mapper.dart
    repositories/
      search_repository_impl.dart
```

### 8.2 favorite

```text
features/im/favorite/
  presentation/
    pages/
      favorites_page.dart
      favorite_detail_page.dart
    controllers/
      favorites_controller.dart
      favorite_detail_controller.dart
    states/
      favorites_state.dart
      favorite_detail_state.dart
    providers/
      favorite_providers.dart
  application/
    usecases/
      load_favorites_use_case.dart
      search_favorites_use_case.dart
      load_favorite_detail_use_case.dart
      remove_favorite_use_case.dart
      resend_favorite_use_case.dart
  domain/
    entities/
      favorite_item.dart
      favorite_detail.dart
    repositories/
      favorite_repository.dart
  infrastructure/
    datasources/
      favorite_remote_data_source.dart
    dtos/
      favorite_item_dto.dart
      favorite_detail_dto.dart
    mappers/
      favorite_dto_mapper.dart
    repositories/
      favorite_repository_impl.dart
```

### 8.3 receipt

```text
features/im/receipt/
  presentation/
    controllers/
      read_receipt_controller.dart
    states/
      read_receipt_state.dart
    widgets/
      read_receipt_summary_sheet.dart
      read_receipt_detail_sheet.dart
    providers/
      receipt_providers.dart
  application/
    usecases/
      load_read_receipt_summary_use_case.dart
      load_read_receipt_detail_use_case.dart
  domain/
    entities/
      read_receipt_summary.dart
      read_receipt_detail_item.dart
    repositories/
      receipt_repository.dart
  infrastructure/
    datasources/
      receipt_remote_data_source.dart
    dtos/
      read_receipt_summary_dto.dart
      read_receipt_detail_item_dto.dart
    mappers/
      receipt_dto_mapper.dart
    repositories/
      receipt_repository_impl.dart
```

### 8.4 call

```text
features/im/call/
  presentation/
    pages/
      incoming_call_page.dart
      outgoing_call_page.dart
      call_session_page.dart
    controllers/
      call_controller.dart
      call_media_controller.dart
    states/
      call_state.dart
      call_media_state.dart
    widgets/
      incoming_call_action_bar.dart
      outgoing_call_status_view.dart
      call_video_stage.dart
      call_bottom_control_bar.dart
    providers/
      call_providers.dart
  application/
    usecases/
      create_call_invite_use_case.dart
      accept_call_use_case.dart
      reject_call_use_case.dart
      cancel_call_use_case.dart
      hangup_call_use_case.dart
      reconnect_call_use_case.dart
      sync_active_call_state_use_case.dart
    coordinators/
      call_coordinator.dart
      call_permission_coordinator.dart
  domain/
    entities/
      call_session.dart
      call_participant.dart
      call_invite.dart
    repositories/
      call_repository.dart
    enums/
      call_type.dart
      call_status.dart
      call_end_reason.dart
  infrastructure/
    datasources/
      call_remote_data_source.dart
      call_socket_data_source.dart
    dtos/
      call_session_dto.dart
      call_signal_event_dto.dart
      rtc_token_dto.dart
    mappers/
      call_dto_mapper.dart
    repositories/
      call_repository_impl.dart
    adapters/
      rtc_gateway_adapter.dart
      janus_signaling_client.dart
```

### 8.5 media

```text
features/im/media/
  presentation/
    pages/
      chat_media_page.dart
    controllers/
      media_browser_controller.dart
    states/
      media_browser_state.dart
    providers/
      media_providers.dart
  application/
    usecases/
      load_chat_media_use_case.dart
      load_group_files_use_case.dart
  domain/
    entities/
      media_item.dart
      file_item.dart
    repositories/
      media_repository.dart
  infrastructure/
    datasources/
      media_remote_data_source.dart
    dtos/
      media_item_dto.dart
      file_item_dto.dart
    mappers/
      media_dto_mapper.dart
    repositories/
      media_repository_impl.dart
```

---

## 9. 第一阶段最小可运行文件集合

优先创建：

1. `main.dart`
2. `app/bootstrap/*`
3. `app/router/*`
4. `core/auth/*`
5. `core/network/*`
6. `core/websocket/*`
7. `features/im/conversation/*`
8. `features/im/chat/*`
9. `features/im/call/*`

---

## 10. 第二阶段扩展文件集合

随后创建：

- `group/*`
- `contact/*`
- `search/*`
- `favorite/*`
- `receipt/*`
- `media/*`
- `call/*`

---

## 11. 创建顺序原则

1. 先 contract，后 impl
2. 先 state，后 widget
3. 先 route args，后 page
4. 先 mapper，后 repository impl
