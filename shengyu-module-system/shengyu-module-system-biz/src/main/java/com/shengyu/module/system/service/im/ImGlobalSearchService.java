package com.shengyu.module.system.service.im;

import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.module.system.controller.app.im.vo.contact.AppImContactRespVO;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationRespVO;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationSearchReqVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessageRespVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessageSearchReqVO;
import com.shengyu.module.system.controller.app.im.vo.search.AppImGlobalSearchReqVO;
import com.shengyu.module.system.controller.app.im.vo.search.AppImGlobalSearchRespVO;
import com.shengyu.module.system.enums.im.ImMessageTypeEnum;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.*;
import java.util.stream.Collectors;

/**
 * IM 全局搜索服务（聚合联系人/群聊/消息/媒体）
 */
@Service
@Slf4j
public class ImGlobalSearchService {

    private static final int MAX_PAGE_SIZE = 50;
    private static final int ALL_TAB_SOURCE_LIMIT = 200;

    @Resource
    private ImContactService contactService;
    @Resource
    private ImConversationService conversationService;
    @Resource
    private ImMessageService messageService;

    public AppImGlobalSearchRespVO search(Long userId, AppImGlobalSearchReqVO reqVO) {
        long start = System.currentTimeMillis();
        AppImGlobalSearchRespVO respVO = new AppImGlobalSearchRespVO();
        if (userId == null || reqVO == null) {
            respVO.setCostMs(System.currentTimeMillis() - start);
            return respVO;
        }
        String keyword = StrUtil.trimToEmpty(reqVO.getKeyword());
        if (StrUtil.isBlank(keyword)) {
            respVO.setCostMs(System.currentTimeMillis() - start);
            return respVO;
        }
        int pageNo = normalizePageNo(reqVO.getPageNo());
        int pageSize = normalizePageSize(reqVO.getPageSize());
        String tab = normalizeTab(reqVO.getTab());
        String sort = normalizeSort(reqVO.getSort());

        AppImGlobalSearchRespVO.Facets facets = new AppImGlobalSearchRespVO.Facets();
        List<AppImGlobalSearchRespVO.Item> pageList;
        long total;

        switch (tab) {
            case "contact":
                PageResult<AppImContactRespVO> contactsPage = safeSearchContactsPage(userId, keyword, pageNo, pageSize);
                long contactTotal = contactsPage.getTotal() != null ? contactsPage.getTotal() : 0L;
                facets.setContact(contactTotal);
                facets.setAll(contactTotal);
                total = contactTotal;
                pageList = safeList(contactsPage.getList()).stream()
                        .map(contact -> buildContactItem(contact, keyword))
                        .collect(Collectors.toList());
                break;
            case "group":
                PageResult<AppImConversationRespVO> groupPage = searchGroups(userId, keyword, pageNo, pageSize);
                long groupTotal = groupPage.getTotal() != null ? groupPage.getTotal() : 0L;
                facets.setGroup(groupTotal);
                facets.setAll(groupTotal);
                total = groupTotal;
                pageList = safeList(groupPage.getList()).stream()
                        .map(group -> buildGroupItem(group, keyword))
                        .collect(Collectors.toList());
                pageList.sort(buildComparator(sort));
                break;
            case "message":
                PageResult<AppImMessageRespVO> messagePage = searchMessages(userId, keyword, reqVO.getChatId(), pageNo, pageSize, false);
                long messageTotal = messagePage.getTotal() != null ? messagePage.getTotal() : 0L;
                facets.setMessage(messageTotal);
                facets.setAll(messageTotal);
                total = messageTotal;
                pageList = safeList(messagePage.getList()).stream()
                        .map(message -> buildMessageItem(message, keyword, false, userId))
                        .collect(Collectors.toList());
                pageList.sort(buildComparator(sort));
                break;
            case "media":
                PageResult<AppImMessageRespVO> mediaPage = searchMessages(userId, keyword, reqVO.getChatId(), pageNo, pageSize, true);
                long mediaTotal = mediaPage.getTotal() != null ? mediaPage.getTotal() : 0L;
                facets.setMedia(mediaTotal);
                facets.setAll(mediaTotal);
                total = mediaTotal;
                pageList = safeList(mediaPage.getList()).stream()
                        .map(message -> buildMessageItem(message, keyword, true, userId))
                        .collect(Collectors.toList());
                pageList.sort(buildComparator(sort));
                break;
            case "all":
            default:
                // 综合：按目标页动态扩大分源拉取窗口，降低深翻页丢失风险
                int requiredWindow = Math.min(Math.max(pageNo * pageSize * 2, pageSize), ALL_TAB_SOURCE_LIMIT);
                WindowResult<AppImContactRespVO> allContactsWindow = collectContactsWindow(userId, keyword, requiredWindow);
                WindowResult<AppImConversationRespVO> allGroupsWindow = collectGroupsWindow(userId, keyword, requiredWindow);
                WindowResult<AppImMessageRespVO> allMessagesWindow = collectMessagesWindow(userId, keyword, reqVO.getChatId(), requiredWindow, false);
                PageResult<AppImMessageRespVO> mediaTotalPage = searchMessages(userId, keyword, reqVO.getChatId(), 1, 1, true);

                long allContactCount = allContactsWindow.getTotal();
                long allGroupCount = allGroupsWindow.getTotal();
                long allMessageCount = allMessagesWindow.getTotal();
                long allMediaCount = mediaTotalPage.getTotal() != null ? mediaTotalPage.getTotal() : 0L;
                facets.setContact(allContactCount);
                facets.setGroup(allGroupCount);
                facets.setMessage(allMessageCount);
                facets.setMedia(allMediaCount);

                List<AppImGlobalSearchRespVO.Item> merged = new ArrayList<>();
                safeList(allContactsWindow.getList()).forEach(contact -> merged.add(buildContactItem(contact, keyword)));
                safeList(allGroupsWindow.getList()).forEach(group -> merged.add(buildGroupItem(group, keyword)));
                safeList(allMessagesWindow.getList()).forEach(message -> merged.add(buildMessageItem(message, keyword, false, userId)));

                merged.sort(buildComparator(sort));
                total = allContactCount + allGroupCount + allMessageCount;
                facets.setAll(total);
                pageList = paginateList(merged, pageNo, pageSize);
                break;
        }

        respVO.setList(pageList);
        respVO.setFacets(facets);
        respVO.setTotal(total);
        respVO.setPageNo(pageNo);
        respVO.setPageSize(pageSize);
        boolean hasMore = (long) pageNo * pageSize < total;
        if (hasMore && (pageList == null || pageList.isEmpty())) {
            hasMore = false;
        }
        respVO.setHasMore(hasMore);
        respVO.setNextCursor("");
        respVO.setCostMs(System.currentTimeMillis() - start);
        return respVO;
    }

    private PageResult<AppImContactRespVO> safeSearchContactsPage(Long userId, String keyword, int pageNo, int pageSize) {
        try {
            return contactService.searchContactsPage(userId, keyword, pageNo, pageSize);
        } catch (Exception e) {
            log.warn("[ImGlobalSearch] searchContacts failed, userId={}, keyword={}", userId, keyword, e);
            return PageResult.empty();
        }
    }

    private PageResult<AppImConversationRespVO> searchGroups(Long userId, String keyword, int pageNo, int pageSize) {
        AppImConversationSearchReqVO reqVO = new AppImConversationSearchReqVO();
        reqVO.setKeyword(keyword);
        reqVO.setConversationType(2);
        reqVO.setPageNo(pageNo);
        reqVO.setPageSize(pageSize);
        return conversationService.searchConversations(userId, reqVO);
    }

    private PageResult<AppImMessageRespVO> searchMessages(Long userId, String keyword, Long chatId,
                                                          int pageNo, int pageSize, boolean mediaOnly) {
        AppImMessageSearchReqVO reqVO = new AppImMessageSearchReqVO();
        reqVO.setKeyword(keyword);
        reqVO.setChatId(chatId);
        reqVO.setPageNo(pageNo);
        reqVO.setPageSize(pageSize);
        if (mediaOnly) {
            reqVO.setCategory("media");
        }
        return messageService.searchMessages(userId, reqVO);
    }

    private WindowResult<AppImContactRespVO> collectContactsWindow(Long userId, String keyword, int windowSize) {
        List<AppImContactRespVO> merged = new ArrayList<>();
        long total = 0L;
        int pageNo = 1;
        while (merged.size() < windowSize) {
            PageResult<AppImContactRespVO> page = safeSearchContactsPage(userId, keyword, pageNo, MAX_PAGE_SIZE);
            if (pageNo == 1) {
                total = page.getTotal() != null ? page.getTotal() : 0L;
            }
            List<AppImContactRespVO> batch = safeList(page.getList());
            if (batch.isEmpty()) {
                break;
            }
            merged.addAll(batch);
            if ((long) pageNo * MAX_PAGE_SIZE >= total) {
                break;
            }
            pageNo++;
        }
        if (merged.size() > windowSize) {
            merged = merged.subList(0, windowSize);
        }
        return new WindowResult<>(merged, total);
    }

    private WindowResult<AppImConversationRespVO> collectGroupsWindow(Long userId, String keyword, int windowSize) {
        List<AppImConversationRespVO> merged = new ArrayList<>();
        long total = 0L;
        int pageNo = 1;
        while (merged.size() < windowSize) {
            PageResult<AppImConversationRespVO> page = searchGroups(userId, keyword, pageNo, MAX_PAGE_SIZE);
            if (pageNo == 1) {
                total = page.getTotal() != null ? page.getTotal() : 0L;
            }
            List<AppImConversationRespVO> batch = safeList(page.getList());
            if (batch.isEmpty()) {
                break;
            }
            merged.addAll(batch);
            if ((long) pageNo * MAX_PAGE_SIZE >= total) {
                break;
            }
            pageNo++;
        }
        if (merged.size() > windowSize) {
            merged = merged.subList(0, windowSize);
        }
        return new WindowResult<>(merged, total);
    }

    private WindowResult<AppImMessageRespVO> collectMessagesWindow(Long userId, String keyword, Long chatId, int windowSize, boolean mediaOnly) {
        List<AppImMessageRespVO> merged = new ArrayList<>();
        long total = 0L;
        int pageNo = 1;
        while (merged.size() < windowSize) {
            PageResult<AppImMessageRespVO> page = searchMessages(userId, keyword, chatId, pageNo, MAX_PAGE_SIZE, mediaOnly);
            if (pageNo == 1) {
                total = page.getTotal() != null ? page.getTotal() : 0L;
            }
            List<AppImMessageRespVO> batch = safeList(page.getList());
            if (batch.isEmpty()) {
                break;
            }
            merged.addAll(batch);
            if ((long) pageNo * MAX_PAGE_SIZE >= total) {
                break;
            }
            pageNo++;
        }
        if (merged.size() > windowSize) {
            merged = merged.subList(0, windowSize);
        }
        return new WindowResult<>(merged, total);
    }

    private AppImGlobalSearchRespVO.Item buildContactItem(AppImContactRespVO contact, String keyword) {
        AppImGlobalSearchRespVO.Item item = new AppImGlobalSearchRespVO.Item();
        String userId = contact != null && contact.getId() != null ? String.valueOf(contact.getId()) : "0";
        String name = contact != null ? StrUtil.nullToEmpty(contact.getNickname()) : "";
        String dept = contact != null ? StrUtil.nullToEmpty(contact.getDeptName()) : "";
        String post = contact != null ? StrUtil.nullToEmpty(contact.getPostName()) : "";
        String subTitle = StrUtil.isNotBlank(dept) ? dept : post;

        item.setId(userId);
        item.setType("contact");
        item.setTitle(name);
        item.setSubTitle(subTitle);
        item.setSnippet(subTitle);
        item.setTime(0L);
        item.setScore(calculateKeywordScore(name, keyword) + calculateKeywordScore(subTitle, keyword));

        Map<String, Object> meta = new HashMap<>();
        meta.put("userId", userId);
        meta.put("avatar", contact != null ? contact.getAvatar() : null);
        item.setMeta(meta);
        return item;
    }

    private AppImGlobalSearchRespVO.Item buildGroupItem(AppImConversationRespVO group, String keyword) {
        AppImGlobalSearchRespVO.Item item = new AppImGlobalSearchRespVO.Item();
        String chatId = group != null && group.getChatId() != null ? String.valueOf(group.getChatId()) : "0";
        String title = group != null ? StrUtil.nullToEmpty(group.getTargetName()) : "";
        String snippet = group != null ? StrUtil.nullToEmpty(group.getLastMessageContent()) : "";
        long time = toEpochMillis(group != null ? group.getLastMessageTime() : null);

        int score = calculateKeywordScore(title, keyword)
                + calculateKeywordScore(snippet, keyword)
                + calculateRecentBonus(time);
        if (group != null && Boolean.TRUE.equals(group.getLastMessageHasAtMe())) {
            score += 20;
        }

        item.setId(chatId);
        item.setType("group");
        item.setTitle(title);
        item.setSubTitle("群聊");
        item.setSnippet(clip(snippet, 120));
        item.setTime(time);
        item.setScore(score);
        item.setChatId(chatId);

        Map<String, Object> meta = new HashMap<>();
        meta.put("conversationType", 2);
        meta.put("targetId", group != null ? group.getTargetId() : null);
        meta.put("targetAvatar", group != null ? group.getTargetAvatar() : null);
        meta.put("memberCount", group != null ? group.getGroupMemberCount() : null);
        item.setMeta(meta);
        return item;
    }

    private AppImGlobalSearchRespVO.Item buildMessageItem(AppImMessageRespVO message, String keyword, boolean forceMediaType, Long currentUserId) {
        AppImGlobalSearchRespVO.Item item = new AppImGlobalSearchRespVO.Item();
        String messageId = message != null && message.getId() != null ? String.valueOf(message.getId()) : "0";
        String chatId = message != null && message.getChatId() != null ? String.valueOf(message.getChatId()) : "0";
        String sequence = message != null && message.getSequence() != null ? String.valueOf(message.getSequence()) : "0";
        String title = message != null ? StrUtil.nullToEmpty(message.getConversationName()) : "";
        String snippet = buildMessageSnippet(message);
        long time = toEpochMillis(message != null ? message.getSendTime() : null);
        Integer messageType = message != null ? message.getMessageType() : null;
        boolean isMedia = isMediaMessageType(messageType);

        int score = calculateKeywordScore(title, keyword)
                + calculateKeywordScore(snippet, keyword)
                + calculateRecentBonus(time);
        if (isMedia) {
            score += 10;
        }

        item.setId(messageId);
        item.setType((forceMediaType || isMedia) ? "media" : "message");
        item.setTitle(title);
        item.setSubTitle(message != null ? StrUtil.nullToEmpty(message.getSenderNickname()) : "");
        item.setSnippet(clip(snippet, 160));
        item.setTime(time);
        item.setScore(score);
        item.setChatId(chatId);
        item.setMessageId(messageId);
        item.setSequence(sequence);

        Integer conversationType = (message != null && message.getGroupId() != null) ? 2 : 1;
        Long targetId;
        if (conversationType == 2) {
            targetId = message != null ? message.getGroupId() : null;
        } else {
            Long senderId = message != null ? message.getSenderId() : null;
            Long receiverId = message != null ? message.getReceiverId() : null;
            if (currentUserId != null && senderId != null && senderId.equals(currentUserId)) {
                targetId = receiverId != null ? receiverId : senderId;
            } else {
                targetId = senderId != null ? senderId : receiverId;
            }
        }

        Map<String, Object> meta = new HashMap<>();
        meta.put("messageType", messageType);
        meta.put("senderId", message != null ? message.getSenderId() : null);
        meta.put("senderName", message != null ? message.getSenderNickname() : null);
        meta.put("senderAvatar", message != null ? message.getSenderAvatar() : null);
        meta.put("conversationType", conversationType);
        meta.put("targetId", targetId);
        meta.put("conversationAvatar", message != null ? message.getConversationAvatar() : null);
        meta.put("targetAvatar", message != null ? message.getConversationAvatar() : null);
        item.setMeta(meta);
        return item;
    }

    private Comparator<AppImGlobalSearchRespVO.Item> buildComparator(String sort) {
        Comparator<AppImGlobalSearchRespVO.Item> byScoreDesc = Comparator.comparing(
                        (AppImGlobalSearchRespVO.Item item) -> item.getScore() != null ? item.getScore() : 0)
                .reversed();
        Comparator<AppImGlobalSearchRespVO.Item> byTimeDesc = Comparator.comparing(
                        (AppImGlobalSearchRespVO.Item item) -> item.getTime() != null ? item.getTime() : 0L)
                .reversed();
        Comparator<AppImGlobalSearchRespVO.Item> byIdDesc = Comparator.comparing(
                (AppImGlobalSearchRespVO.Item item) -> StrUtil.nullToEmpty(item.getId())).reversed();
        if ("recent".equals(sort)) {
            return byTimeDesc.thenComparing(byScoreDesc).thenComparing(byIdDesc);
        }
        return byScoreDesc.thenComparing(byTimeDesc).thenComparing(byIdDesc);
    }

    private int calculateKeywordScore(String text, String keyword) {
        if (StrUtil.isBlank(text) || StrUtil.isBlank(keyword)) {
            return 0;
        }
        String source = text.toLowerCase();
        String kw = keyword.toLowerCase();
        if (source.equals(kw)) {
            return 100;
        }
        if (source.startsWith(kw)) {
            return 60;
        }
        if (source.contains(kw)) {
            return 30;
        }
        return 0;
    }

    private int calculateRecentBonus(long timeMillis) {
        if (timeMillis <= 0) {
            return 0;
        }
        long now = System.currentTimeMillis();
        long delta = now - timeMillis;
        if (delta < 0) {
            return 0;
        }
        long dayMillis = 24L * 60 * 60 * 1000;
        if (delta <= 3 * dayMillis) {
            return 30;
        }
        if (delta <= 7 * dayMillis) {
            return 15;
        }
        return 0;
    }

    private boolean isMediaMessageType(Integer messageType) {
        if (messageType == null) {
            return false;
        }
        return messageType == ImMessageTypeEnum.IMAGE.getType()
                || messageType == ImMessageTypeEnum.VIDEO.getType()
                || messageType == ImMessageTypeEnum.FILE.getType();
    }

    private String buildMessageSnippet(AppImMessageRespVO message) {
        if (message == null) {
            return "";
        }
        Integer messageType = message.getMessageType();
        String content = StrUtil.nullToEmpty(message.getContent());
        if (messageType == null) {
            return content;
        }
        if (Objects.equals(messageType, ImMessageTypeEnum.IMAGE.getType())) {
            return "[图片]";
        }
        if (Objects.equals(messageType, ImMessageTypeEnum.VIDEO.getType())) {
            return "[视频]";
        }
        if (Objects.equals(messageType, ImMessageTypeEnum.FILE.getType())) {
            return "[文件]";
        }
        if (Objects.equals(messageType, ImMessageTypeEnum.VOICE.getType())) {
            return "[语音]";
        }
        if (Objects.equals(messageType, ImMessageTypeEnum.LOCATION.getType())) {
            return "[位置]";
        }
        if (Objects.equals(messageType, ImMessageTypeEnum.EMOJI.getType())) {
            return "[表情]";
        }
        if (Objects.equals(messageType, ImMessageTypeEnum.STICKER.getType())) {
            return "[动画表情]";
        }
        if (content.startsWith("{") || content.startsWith("[")) {
            return "[消息]";
        }
        return content;
    }

    private long toEpochMillis(LocalDateTime dateTime) {
        if (dateTime == null) {
            return 0L;
        }
        return dateTime.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli();
    }

    private int normalizePageNo(Integer pageNo) {
        if (pageNo == null || pageNo < 1) {
            return 1;
        }
        return pageNo;
    }

    private int normalizePageSize(Integer pageSize) {
        if (pageSize == null || pageSize < 1) {
            return 20;
        }
        return Math.min(pageSize, MAX_PAGE_SIZE);
    }

    private String normalizeTab(String tab) {
        String value = StrUtil.trimToEmpty(tab).toLowerCase();
        switch (value) {
            case "message":
            case "contact":
            case "group":
            case "media":
                return value;
            case "all":
            default:
                return "all";
        }
    }

    private String normalizeSort(String sort) {
        String value = StrUtil.trimToEmpty(sort).toLowerCase();
        if ("recent".equals(value)) {
            return "recent";
        }
        return "relevance";
    }

    private String clip(String source, int maxLen) {
        if (source == null) {
            return "";
        }
        if (source.length() <= maxLen) {
            return source;
        }
        return source.substring(0, maxLen) + "...";
    }

    private <T> List<T> paginateList(List<T> list, int pageNo, int pageSize) {
        if (list == null || list.isEmpty()) {
            return Collections.emptyList();
        }
        int from = (pageNo - 1) * pageSize;
        if (from >= list.size()) {
            return Collections.emptyList();
        }
        int to = Math.min(from + pageSize, list.size());
        return new ArrayList<>(list.subList(from, to));
    }

    private <T> List<T> safeList(List<T> list) {
        if (list == null) {
            return Collections.emptyList();
        }
        return list;
    }

    private static class WindowResult<T> {
        private final List<T> list;
        private final long total;

        private WindowResult(List<T> list, long total) {
            this.list = list != null ? list : Collections.emptyList();
            this.total = total;
        }

        private List<T> getList() {
            return list;
        }

        private long getTotal() {
            return total;
        }
    }
}
