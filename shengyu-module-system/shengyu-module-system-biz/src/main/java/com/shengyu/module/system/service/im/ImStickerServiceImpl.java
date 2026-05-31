package com.shengyu.module.system.service.im;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.StrUtil;
import cn.hutool.crypto.digest.DigestUtil;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.shengyu.module.infra.api.file.FileApi;
import com.shengyu.module.infra.api.file.dto.FileDTO;
import com.shengyu.module.system.controller.app.im.vo.sticker.AppImStickerCollectReqVO;
import com.shengyu.module.system.controller.app.im.vo.sticker.AppImStickerListRespVO;
import com.shengyu.module.system.controller.app.im.vo.sticker.AppImStickerRespVO;
import com.shengyu.module.system.controller.app.im.vo.sticker.AppImStickerSortReqVO;
import com.shengyu.module.system.controller.app.im.vo.sticker.AppImStickerUploadReqVO;
import com.shengyu.module.system.dal.dataobject.im.ImChatMessageDO;
import com.shengyu.module.system.dal.dataobject.im.ImChatUserDO;
import com.shengyu.module.system.dal.dataobject.im.ImUserStickerDO;
import com.shengyu.module.system.dal.dataobject.im.ImUserStickerRecentDO;
import com.shengyu.module.system.dal.mysql.im.ImChatMessageMapper;
import com.shengyu.module.system.dal.mysql.im.ImChatUserMapper;
import com.shengyu.module.system.dal.mysql.im.ImUserStickerMapper;
import com.shengyu.module.system.dal.mysql.im.ImUserStickerRecentMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.module.system.enums.ErrorCodeConstants.MESSAGE_NOT_EXISTS;
import static com.shengyu.module.system.enums.ErrorCodeConstants.STICKER_COLLECT_NOT_SUPPORTED;
import static com.shengyu.module.system.enums.ErrorCodeConstants.STICKER_NOT_EXISTS;

@Service
@Slf4j
public class ImStickerServiceImpl implements ImStickerService {

    private static final int STICKER_STATUS_ACTIVE = 1;
    private static final int STICKER_STATUS_REMOVED = 2;
    private static final int STICKER_SOURCE_UPLOAD = 1;
    private static final int STICKER_SOURCE_COLLECT = 2;
    private static final int RECENT_LIMIT = 20;

    @Resource
    private ImUserStickerMapper userStickerMapper;

    @Resource
    private ImUserStickerRecentMapper userStickerRecentMapper;

    @Resource
    private ImChatMessageMapper chatMessageMapper;

    @Resource
    private ImChatUserMapper chatUserMapper;

    @Resource
    private FileApi fileApi;

    @Override
    public AppImStickerListRespVO getStickerList(Long userId) {
        List<ImUserStickerDO> favorites = userStickerMapper.selectActiveByUserId(userId);
        List<ImUserStickerRecentDO> recentList = userStickerRecentMapper.selectRecentByUserId(userId, RECENT_LIMIT);

        Map<Long, ImUserStickerDO> stickerMap = favorites.stream()
                .filter(item -> item != null && item.getId() != null)
                .collect(Collectors.toMap(ImUserStickerDO::getId, item -> item, (a, b) -> a, HashMap::new));
        if (CollUtil.isNotEmpty(recentList)) {
            List<Long> missingIds = recentList.stream()
                    .map(ImUserStickerRecentDO::getStickerId)
                    .filter(id -> id != null && !stickerMap.containsKey(id))
                    .collect(Collectors.toList());
            if (CollUtil.isNotEmpty(missingIds)) {
                List<ImUserStickerDO> missing = userStickerMapper.selectBatchIds(missingIds);
                if (CollUtil.isNotEmpty(missing)) {
                    missing.stream()
                            .filter(item -> item != null && Objects.equals(item.getStatus(), STICKER_STATUS_ACTIVE))
                            .forEach(item -> stickerMap.put(item.getId(), item));
                }
            }
        }

        AppImStickerListRespVO respVO = new AppImStickerListRespVO();
        respVO.setVersion(System.currentTimeMillis());
        respVO.setFavorites(favorites.stream().map(item -> toRespVO(item, false)).collect(Collectors.toList()));
        respVO.setRecent(buildRecentList(recentList, stickerMap));
        return respVO;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public AppImStickerRespVO uploadSticker(Long userId, AppImStickerUploadReqVO reqVO) {
        return upsertSticker(userId, reqVO.getFileId(), null, reqVO.getUrl(), buildStickerKey(reqVO.getMd5(), reqVO.getFileId(), reqVO.getUrl()),
                reqVO.getWidth(), reqVO.getHeight(), reqVO.getMimeType(), reqVO.getName(), STICKER_SOURCE_UPLOAD, false);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public AppImStickerRespVO collectSticker(Long userId, AppImStickerCollectReqVO reqVO) {
        ImChatMessageDO message = chatMessageMapper.selectById(reqVO.getMessageId());
        if (message == null) {
            throw exception(MESSAGE_NOT_EXISTS);
        }
        ImChatUserDO chatUser = chatUserMapper.selectAnyByUserIdAndChatId(userId, message.getChatId());
        if (chatUser == null) {
            throw exception(MESSAGE_NOT_EXISTS);
        }

        JSONObject payload = resolveCollectPayload(message);
        Long fileId = payload.getLong("fileId", 0L);
        Long thumbFileId = payload.getLong("thumbFileId", null);
        String url = payload.getStr("url", "");
        String md5 = buildStickerKey(payload.getStr("md5", null), fileId, url);
        Integer width = payload.getInt("width", null);
        Integer height = payload.getInt("height", null);
        String mimeType = payload.getStr("mimeType", payload.getStr("fileType", null));
        String name = payload.getStr("name", payload.getStr("fileName", null));

        AppImStickerRespVO respVO = upsertSticker(userId, fileId, thumbFileId, url, md5, width, height, mimeType, name, STICKER_SOURCE_COLLECT, false);
        respVO.setDuplicated(Boolean.TRUE.equals(respVO.getDuplicated()));
        return respVO;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void removeSticker(Long userId, Long stickerId) {
        ImUserStickerDO sticker = userStickerMapper.selectActiveByIdAndUserId(stickerId, userId);
        if (sticker == null) {
            throw exception(STICKER_NOT_EXISTS);
        }
        sticker.setStatus(STICKER_STATUS_REMOVED);
        userStickerMapper.updateById(sticker);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void sortStickers(Long userId, AppImStickerSortReqVO reqVO) {
        if (reqVO == null || CollUtil.isEmpty(reqVO.getItems())) {
            return;
        }
        for (AppImStickerSortReqVO.Item item : reqVO.getItems()) {
            if (item == null || item.getStickerId() == null) {
                continue;
            }
            ImUserStickerDO sticker = userStickerMapper.selectActiveByIdAndUserId(item.getStickerId(), userId);
            if (sticker == null) {
                continue;
            }
            sticker.setSortNo(item.getSortNo() == null ? 0 : item.getSortNo());
            userStickerMapper.updateById(sticker);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void recordRecentUse(Long userId, Long stickerId) {
        ImUserStickerDO sticker = userStickerMapper.selectActiveByIdAndUserId(stickerId, userId);
        if (sticker == null) {
            throw exception(STICKER_NOT_EXISTS);
        }
        LocalDateTime now = LocalDateTime.now();
        ImUserStickerRecentDO recent = userStickerRecentMapper.selectByUserIdAndStickerId(userId, stickerId);
        if (recent == null) {
            recent = ImUserStickerRecentDO.builder()
                    .userId(userId)
                    .stickerId(stickerId)
                    .lastUsedAt(now)
                    .useCount(1)
                    .build();
            userStickerRecentMapper.insert(recent);
            return;
        }
        recent.setLastUsedAt(now);
        recent.setUseCount((recent.getUseCount() == null ? 0 : recent.getUseCount()) + 1);
        userStickerRecentMapper.updateById(recent);
    }

    private AppImStickerRespVO upsertSticker(Long userId, Long fileId, Long thumbFileId, String url, String md5,
                                             Integer width, Integer height, String mimeType, String name,
                                             Integer sourceType, boolean duplicated) {
        String key = buildStickerKey(md5, fileId, url);
        ImUserStickerDO existing = userStickerMapper.selectUndeletedByUserIdAndMd5(userId, key);
        if (existing != null) {
            return handleExistingSticker(userId, existing, fileId, thumbFileId, url, width, height, mimeType, name, sourceType, duplicated);
        }

        ImUserStickerDO sticker = ImUserStickerDO.builder()
                .userId(userId)
                .fileId(fileId == null ? 0L : fileId)
                .thumbFileId(thumbFileId)
                .name(name)
                .md5(key)
                .width(width)
                .height(height)
                .mimeType(mimeType)
                .sourceType(sourceType)
                .sortNo(nextSortNo(userId))
                .status(STICKER_STATUS_ACTIVE)
                .build();
        try {
            userStickerMapper.insert(sticker);
        } catch (DuplicateKeyException ex) {
            ImUserStickerDO conflict = userStickerMapper.selectUndeletedByUserIdAndMd5(userId, key);
            if (conflict != null) {
                log.warn("[ImStickerService] duplicate sticker upsert resolved by query, userId={}, key={}", userId, key);
                return handleExistingSticker(userId, conflict, fileId, thumbFileId, url, width, height, mimeType, name, sourceType, duplicated);
            }
            throw ex;
        }

        AppImStickerRespVO respVO = toRespVO(sticker, duplicated);
        if (StrUtil.isBlank(respVO.getUrl()) && StrUtil.isNotBlank(url)) {
            respVO.setUrl(url);
        }
        respVO.setDuplicated(duplicated);
        return respVO;
    }

    private AppImStickerRespVO handleExistingSticker(Long userId, ImUserStickerDO existing,
                                                     Long fileId, Long thumbFileId, String url,
                                                     Integer width, Integer height, String mimeType, String name,
                                                     Integer sourceType, boolean duplicated) {
        if (existing == null) {
            return null;
        }
        if (Objects.equals(existing.getStatus(), STICKER_STATUS_ACTIVE)) {
            AppImStickerRespVO respVO = toRespVO(existing, true);
            if (StrUtil.isBlank(respVO.getUrl()) && StrUtil.isNotBlank(url)) {
                respVO.setUrl(url);
            }
            respVO.setDuplicated(true);
            return respVO;
        }

        existing.setFileId(fileId == null ? 0L : fileId);
        existing.setThumbFileId(thumbFileId);
        if (StrUtil.isNotBlank(name)) {
            existing.setName(name);
        }
        if (width != null) {
            existing.setWidth(width);
        }
        if (height != null) {
            existing.setHeight(height);
        }
        if (StrUtil.isNotBlank(mimeType)) {
            existing.setMimeType(mimeType);
        }
        if (sourceType != null) {
            existing.setSourceType(sourceType);
        }
        if (existing.getSortNo() == null || existing.getSortNo() <= 0) {
            existing.setSortNo(nextSortNo(userId));
        }
        existing.setStatus(STICKER_STATUS_ACTIVE);
        userStickerMapper.updateById(existing);

        AppImStickerRespVO respVO = toRespVO(existing, duplicated);
        if (StrUtil.isBlank(respVO.getUrl()) && StrUtil.isNotBlank(url)) {
            respVO.setUrl(url);
        }
        respVO.setDuplicated(duplicated);
        return respVO;
    }

    private List<AppImStickerRespVO> buildRecentList(List<ImUserStickerRecentDO> recentList, Map<Long, ImUserStickerDO> stickerMap) {
        if (CollUtil.isEmpty(recentList)) {
            return new ArrayList<>();
        }
        return recentList.stream()
                .sorted(Comparator.comparing(ImUserStickerRecentDO::getLastUsedAt, Comparator.nullsLast(Comparator.reverseOrder())))
                .map(item -> stickerMap.get(item.getStickerId()))
                .filter(item -> item != null && Objects.equals(item.getStatus(), STICKER_STATUS_ACTIVE))
                .map(item -> toRespVO(item, false))
                .collect(Collectors.toList());
    }

    private AppImStickerRespVO toRespVO(ImUserStickerDO sticker, boolean duplicated) {
        AppImStickerRespVO respVO = new AppImStickerRespVO();
        respVO.setStickerId(sticker.getId());
        respVO.setFileId(sticker.getFileId());
        respVO.setThumbFileId(sticker.getThumbFileId());
        respVO.setName(sticker.getName());
        respVO.setMd5(sticker.getMd5());
        respVO.setWidth(sticker.getWidth());
        respVO.setHeight(sticker.getHeight());
        respVO.setMimeType(sticker.getMimeType());
        respVO.setSourceType(sticker.getSourceType());
        respVO.setSortNo(sticker.getSortNo());
        respVO.setDuplicated(duplicated);
        fillFileUrls(respVO, sticker.getFileId(), sticker.getThumbFileId());
        return respVO;
    }

    private void fillFileUrls(AppImStickerRespVO respVO, Long fileId, Long thumbFileId) {
        if (fileId != null && fileId > 0) {
            FileDTO fileDTO = fileApi.getFile(fileId);
            if (fileDTO != null) {
                respVO.setUrl(fileDTO.getUrl());
                if (StrUtil.isBlank(respVO.getName())) {
                    respVO.setName(fileDTO.getName());
                }
                if (StrUtil.isBlank(respVO.getMimeType())) {
                    respVO.setMimeType(fileDTO.getType());
                }
            }
        }
        if (thumbFileId != null && thumbFileId > 0) {
            FileDTO thumbFile = fileApi.getFile(thumbFileId);
            if (thumbFile != null) {
                respVO.setThumbUrl(thumbFile.getUrl());
            }
        }
    }

    private JSONObject resolveCollectPayload(ImChatMessageDO message) {
        Integer messageType = message.getMessageType();
        JSONObject extra = parseJson(message.getExtra());
        if (Objects.equals(messageType, 8)) {
            if (extra != null) {
                return extra;
            }
            throw exception(STICKER_COLLECT_NOT_SUPPORTED);
        }
        if (Objects.equals(messageType, 2)) {
            JSONObject payload = extra != null ? extra : JSONUtil.createObj();
            if (StrUtil.isBlank(payload.getStr("url"))) {
                payload.set("url", message.getContent());
            }
            if (payload.getLong("fileId", null) == null) {
                payload.set("fileId", 0L);
            }
            return payload;
        }
        throw exception(STICKER_COLLECT_NOT_SUPPORTED);
    }

    private JSONObject parseJson(String raw) {
        if (StrUtil.isBlank(raw)) {
            return null;
        }
        try {
            return JSONUtil.parseObj(raw);
        } catch (Exception ex) {
            log.warn("[ImStickerService] parseJson failed, raw={}", raw, ex);
            return null;
        }
    }

    private String buildStickerKey(String md5, Long fileId, String url) {
        if (StrUtil.isNotBlank(md5)) {
            String normalizedMd5 = md5.trim();
            return normalizedMd5.length() <= 64 ? normalizedMd5 : "raw:" + DigestUtil.md5Hex(normalizedMd5);
        }
        if (fileId != null && fileId > 0) {
            return "file:" + fileId;
        }
        if (StrUtil.isNotBlank(url)) {
            return "url:" + DigestUtil.md5Hex(url.trim());
        }
        return "unknown";
    }

    private Integer nextSortNo(Long userId) {
        List<ImUserStickerDO> list = userStickerMapper.selectActiveByUserId(userId);
        if (CollUtil.isEmpty(list)) {
            return 1;
        }
        Integer maxSortNo = list.stream()
                .map(ImUserStickerDO::getSortNo)
                .filter(Objects::nonNull)
                .max(Integer::compareTo)
                .orElse(0);
        return maxSortNo + 1;
    }
}
