package com.shengyu.module.system.service.im;

import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.shengyu.framework.common.exception.util.ServiceExceptionUtil;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.tenant.core.context.TenantContextHolder;
import com.shengyu.module.system.controller.app.im.vo.favorite.AppImFavoritePageReqVO;
import com.shengyu.module.system.controller.app.im.vo.favorite.AppImFavoriteRespVO;
import com.shengyu.module.system.controller.app.im.vo.favorite.AppImFavoriteSearchReqVO;
import com.shengyu.module.system.controller.app.im.vo.favorite.AppImFavoriteSearchRespVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessageSendReqVO;
import com.shengyu.module.system.dal.dataobject.im.ImChatMessageDO;
import com.shengyu.module.system.dal.dataobject.im.ImChatUserDO;
import com.shengyu.module.system.dal.dataobject.im.ImMessageFavoriteDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.mysql.im.ImChatMessageMapper;
import com.shengyu.module.system.dal.mysql.im.ImChatUserMapper;
import com.shengyu.module.system.dal.mysql.im.ImMessageFavoriteMapper;
import com.shengyu.module.system.dal.mysql.user.AdminUserMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.util.*;
import java.util.stream.Collectors;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.module.system.enums.ErrorCodeConstants.MESSAGE_NOT_EXISTS;

@Service
@Slf4j
public class ImFavoriteServiceImpl implements ImFavoriteService {

    @Resource
    private ImMessageFavoriteMapper favoriteMapper;

    @Resource
    private ImChatMessageMapper chatMessageMapper;

    @Resource
    private ImChatUserMapper chatUserMapper;

    @Resource
    private AdminUserMapper adminUserMapper;

    @Resource
    private ImMessageService messageService;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void addFavorite(Long userId, Long messageId) {
        ImChatMessageDO message = chatMessageMapper.selectById(messageId);
        if (message == null) {
            throw exception(MESSAGE_NOT_EXISTS);
        }
        ImChatUserDO chatUser = chatUserMapper.selectAnyByUserIdAndChatId(userId, message.getChatId());
        if (chatUser == null) {
            throw exception(MESSAGE_NOT_EXISTS);
        }

        ImMessageFavoriteDO favorite = ImMessageFavoriteDO.builder()
                .userId(userId)
                .messageId(messageId)
                .chatId(message.getChatId())
                .anchorSequence(message.getSequence())
                .messageType(message.getMessageType())
                .messagePreview(buildMessagePreview(message.getMessageType(), message.getContent(), null))
                .messageContent(message.getContent())
                .messageExtra(message.getExtra())
                .messageSnapshot(buildMessageSnapshot(message))
                .sourceSendTime(message.getSendTime())
                .build();
        favoriteMapper.insert(favorite);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void removeFavorite(Long userId, Long favoriteId) {
        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }
        ImMessageFavoriteDO favorite = favoriteMapper.selectByIdAndUserId(tenantId, userId, favoriteId);
        if (favorite == null) {
            return;
        }
        favoriteMapper.deleteById(favorite.getId());
    }

    @Override
    public PageResult<AppImFavoriteRespVO> getFavoritePage(Long userId, AppImFavoritePageReqVO reqVO) {
        Integer pageNo = reqVO != null && reqVO.getPageNo() != null && reqVO.getPageNo() > 0 ? reqVO.getPageNo() : 1;
        Integer pageSize = reqVO != null && reqVO.getPageSize() != null && reqVO.getPageSize() > 0 ? reqVO.getPageSize() : 20;
        if (pageSize > 100) {
            pageSize = 100;
        }
        int offset = (pageNo - 1) * pageSize;
        String tab = normalizeSearchTab(reqVO != null ? reqVO.getTab() : null);

        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }

        Long total = favoriteMapper.countByUserIdAndTab(tenantId, userId, tab);
        if (total == null || total <= 0) {
            return new PageResult<>(new ArrayList<>(), 0L);
        }

        List<ImMessageFavoriteDO> favorites = favoriteMapper.selectPageByUserId(tenantId, userId, tab, offset, pageSize);
        if (favorites == null || favorites.isEmpty()) {
            return new PageResult<>(new ArrayList<>(), total);
        }

        // 批量查询发送者信息
        Map<Long, AdminUserDO> senderMap = buildSenderMapFromFavorites(favorites);
        Long currentUserId = userId;

        List<AppImFavoriteRespVO> list = new ArrayList<>();
        for (ImMessageFavoriteDO favorite : favorites) {
            list.add(buildFavoriteResp(favorite, senderMap, currentUserId));
        }

        return new PageResult<>(list, total);
    }

    @Override
    public AppImFavoriteSearchRespVO searchFavoritePage(Long userId, AppImFavoriteSearchReqVO reqVO) {
        long startMs = System.currentTimeMillis();
        AppImFavoriteSearchRespVO resp = new AppImFavoriteSearchRespVO();
        Integer pageNo = reqVO != null && reqVO.getPageNo() != null && reqVO.getPageNo() > 0 ? reqVO.getPageNo() : 1;
        Integer pageSize = reqVO != null && reqVO.getPageSize() != null && reqVO.getPageSize() > 0 ? reqVO.getPageSize() : 20;
        if (pageSize > 50) {
            pageSize = 50;
        }
        int offset = (pageNo - 1) * pageSize;
        String keyword = reqVO != null ? StrUtil.trim(reqVO.getKeyword()) : "";
        if (keyword.length() < 2) {
            resp.setPageNo(pageNo);
            resp.setPageSize(pageSize);
            resp.setHasMore(false);
            resp.setCostMs(Math.max(0L, System.currentTimeMillis() - startMs));
            return resp;
        }
        String tab = normalizeSearchTab(reqVO != null ? reqVO.getTab() : null);

        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }

        List<Map<String, Object>> groupedTypeCounts = favoriteMapper.selectSearchTypeCountsByUser(tenantId, userId, keyword);
        long allCount = 0L;
        long mediaCount = 0L;
        long fileCount = 0L;
        if (groupedTypeCounts != null && !groupedTypeCounts.isEmpty()) {
            for (Map<String, Object> row : groupedTypeCounts) {
                if (row == null) {
                    continue;
                }
                int type = parseInt(row.get("messageType"));
                long cnt = parseLong(row.get("cnt"));
                allCount += cnt;
                if (type == 2 || type == 4) {
                    mediaCount += cnt;
                }
                if (type == 5) {
                    fileCount += cnt;
                }
            }
        }
        long normalCount = Math.max(0L, allCount - mediaCount - fileCount);
        long total = resolveTotalByTab(tab, allCount, normalCount, mediaCount, fileCount);
        AppImFavoriteSearchRespVO.Facets facets = new AppImFavoriteSearchRespVO.Facets();
        facets.setNormal(normalCount);
        facets.setMedia(mediaCount);
        facets.setFile(fileCount);
        facets.setAll(allCount);
        resp.setFacets(facets);
        resp.setTotal(total);
        resp.setPageNo(pageNo);
        resp.setPageSize(pageSize);
        resp.setHasMore((long) pageNo * pageSize < total);

        if (total <= 0L) {
            resp.setList(new ArrayList<>());
            resp.setCostMs(Math.max(0L, System.currentTimeMillis() - startMs));
            return resp;
        }

        List<ImMessageFavoriteDO> favorites = favoriteMapper.selectSearchPageByUserId(tenantId, userId, keyword, tab, offset, pageSize);
        List<AppImFavoriteRespVO> list = new ArrayList<>();
        if (favorites != null && !favorites.isEmpty()) {
            // 批量查询发送者信息
            Map<Long, AdminUserDO> senderMap = buildSenderMapFromFavorites(favorites);
            Long currentUserId = userId;
            for (ImMessageFavoriteDO favorite : favorites) {
                list.add(buildFavoriteResp(favorite, senderMap, currentUserId));
            }
        }
        resp.setList(list);
        resp.setCostMs(Math.max(0L, System.currentTimeMillis() - startMs));
        return resp;
    }

    @Override
    public AppImFavoriteRespVO getFavoriteDetail(Long userId, Long favoriteId) {
        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }
        ImMessageFavoriteDO favorite = favoriteMapper.selectByIdAndUserId(tenantId, userId, favoriteId);
        if (favorite == null) {
            throw exception(MESSAGE_NOT_EXISTS);
        }
        return buildFavoriteResp(favorite);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long resendFavorite(Long userId, Long favoriteId, Long targetChatId) {
        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }
        ImMessageFavoriteDO favorite = favoriteMapper.selectByIdAndUserId(tenantId, userId, favoriteId);
        if (favorite == null) {
            throw exception(MESSAGE_NOT_EXISTS);
        }
        Integer messageType = favorite.getMessageType();
        String messageContent = favorite.getMessageContent();
        String messageExtra = favorite.getMessageExtra();
        if (StrUtil.isNotBlank(favorite.getMessageSnapshot())) {
            try {
                JSONObject snapshot = JSONUtil.parseObj(favorite.getMessageSnapshot());
                Integer snapshotType = snapshot.getInt("messageType", null);
                if (snapshotType != null) {
                    messageType = snapshotType;
                }
                String snapshotContent = snapshot.getStr("content", null);
                if (snapshotContent != null) {
                    messageContent = snapshotContent;
                }
                String snapshotExtra = snapshot.getStr("extra", null);
                if (snapshotExtra != null) {
                    messageExtra = snapshotExtra;
                }
            } catch (Exception ignore) {
            }
        }
        if (messageType == null || messageType <= 0) {
            throw ServiceExceptionUtil.invalidParamException("收藏消息类型无效");
        }
        AppImMessageSendReqVO sendReqVO = new AppImMessageSendReqVO();
        sendReqVO.setChatId(targetChatId);
        sendReqVO.setMessageType(messageType);
        sendReqVO.setContent(messageContent != null ? messageContent : "");
        sendReqVO.setExtra(messageExtra);
        return messageService.sendMessage(userId, sendReqVO);
    }

    private AppImFavoriteRespVO buildFavoriteResp(ImMessageFavoriteDO favorite) {
        return buildFavoriteResp(favorite, null, null);
    }

    private AppImFavoriteRespVO buildFavoriteResp(ImMessageFavoriteDO favorite,
                                                  Map<Long, AdminUserDO> senderMap,
                                                  Long currentUserId) {
        AppImFavoriteRespVO respVO = new AppImFavoriteRespVO();
        respVO.setFavoriteId(favorite.getId());
        respVO.setMessageId(favorite.getMessageId());
        respVO.setChatId(favorite.getChatId());
        respVO.setMessageType(favorite.getMessageType());
        respVO.setMessagePreview(StrUtil.isNotBlank(favorite.getMessagePreview()) ? favorite.getMessagePreview() : "[消息]");
        respVO.setMessageContent(favorite.getMessageContent());
        respVO.setMessageExtra(favorite.getMessageExtra());
        respVO.setMessageSnapshot(favorite.getMessageSnapshot());
        respVO.setSendTime(favorite.getSourceSendTime());
        respVO.setFavoriteTime(favorite.getCreateTime());

        // 填充发送者信息
        Long senderId = extractSenderId(favorite);
        respVO.setSenderId(senderId);
        if (senderId != null) {
            AdminUserDO sender = senderMap != null ? senderMap.get(senderId) : adminUserMapper.selectById(senderId);
            if (sender != null) {
                respVO.setSenderNickname(sender.getNickname());
                respVO.setSenderAvatar(sender.getAvatar());
            }
        }
        respVO.setIsSelf(senderId != null && senderId.equals(currentUserId));

        return respVO;
    }

    /**
     * 从收藏列表中提取所有发送者ID并批量查询用户信息
     */
    private Map<Long, AdminUserDO> buildSenderMapFromFavorites(List<ImMessageFavoriteDO> favorites) {
        Set<Long> senderIds = new LinkedHashSet<>();
        for (ImMessageFavoriteDO favorite : favorites) {
            Long senderId = extractSenderId(favorite);
            if (senderId != null) {
                senderIds.add(senderId);
            }
        }
        if (senderIds.isEmpty()) {
            return new HashMap<>();
        }
        return adminUserMapper.selectBatchIds(senderIds).stream()
                .filter(Objects::nonNull)
                .collect(Collectors.toMap(AdminUserDO::getId, item -> item, (left, right) -> left));
    }

    /**
     * 从收藏记录中提取发送者ID
     * 优先从 messageSnapshot JSON 中解析 senderId
     */
    private Long extractSenderId(ImMessageFavoriteDO favorite) {
        String snapshot = favorite.getMessageSnapshot();
        if (StrUtil.isBlank(snapshot)) {
            return null;
        }
        try {
            JSONObject snapshotObj = JSONUtil.parseObj(snapshot);
            Long senderId = snapshotObj.getLong("senderId", null);
            if (senderId == null) {
                // 兼容字符串类型的 senderId
                String senderIdStr = snapshotObj.getStr("senderId");
                if (StrUtil.isNotBlank(senderIdStr)) {
                    senderId = Long.parseLong(senderIdStr);
                }
            }
            return senderId;
        } catch (Exception e) {
            log.warn("[extractSenderId][解析 messageSnapshot 失败, favoriteId={}, snapshot={}]", favorite.getId(), snapshot, e);
            return null;
        }
    }

    private String buildMessageSnapshot(ImChatMessageDO message) {
        return JSONUtil.toJsonStr(message);
    }

    private String normalizeSearchTab(String tab) {
        if (StrUtil.isBlank(tab)) {
            return "default";
        }
        String normalized = StrUtil.trim(tab).toLowerCase();
        if ("normal".equals(normalized) || "media".equals(normalized) || "file".equals(normalized)) {
            return normalized;
        }
        return "default";
    }

    private long resolveTotalByTab(String tab, long all, long normal, long media, long file) {
        if ("normal".equals(tab)) {
            return normal;
        }
        if ("media".equals(tab)) {
            return media;
        }
        if ("file".equals(tab)) {
            return file;
        }
        return all;
    }

    private int parseInt(Object value) {
        if (value == null) {
            return 0;
        }
        try {
            return Integer.parseInt(String.valueOf(value));
        } catch (Exception e) {
            return 0;
        }
    }

    private long parseLong(Object value) {
        if (value == null) {
            return 0L;
        }
        try {
            return Long.parseLong(String.valueOf(value));
        } catch (Exception e) {
            return 0L;
        }
    }

    private String buildMessagePreview(Integer messageType, String content, String fallback) {
        if (messageType == null) {
            return StrUtil.isNotBlank(fallback) ? fallback : "[消息]";
        }
        switch (messageType) {
            case 1:
                if (StrUtil.isBlank(content)) {
                    return StrUtil.isNotBlank(fallback) ? fallback : "";
                }
                return content.length() > 50 ? content.substring(0, 50) + "..." : content;
            case 2:
                return "[图片]";
            case 3:
                return "[语音]";
            case 4:
                return "[视频]";
            case 5:
                return "[文件]";
            case 6:
                return "[位置]";
            case 7:
                return "[表情]";
            case 8:
                return "[动画表情]";
            case 9:
                return buildCustomPreview(content, fallback);
            case 10:
                return "[系统消息]";
            default:
                return StrUtil.isNotBlank(fallback) ? fallback : "[消息]";
        }
    }

    private String buildCustomPreview(String content, String fallback) {
        if (StrUtil.isBlank(content)) {
            return StrUtil.isNotBlank(fallback) ? fallback : "[自定义消息]";
        }
        try {
            JSONObject obj = JSONUtil.parseObj(content);
            String customType = obj.getStr("type", "");
            if ("FORWARD_COMBINE".equals(customType)) {
                return "[聊天记录]";
            }
            if ("STICKER".equals(customType)) {
                return "[动画表情]";
            }
            if ("CONTACT_CARD".equals(customType)) {
                return "[名片]";
            }
        } catch (Exception ignore) {
        }
        return StrUtil.isNotBlank(fallback) ? fallback : "[自定义消息]";
    }
}
