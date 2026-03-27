package com.shengyu.module.system.service.im;

import com.shengyu.module.system.controller.app.im.vo.sticker.AppImStickerCollectReqVO;
import com.shengyu.module.system.controller.app.im.vo.sticker.AppImStickerListRespVO;
import com.shengyu.module.system.controller.app.im.vo.sticker.AppImStickerRespVO;
import com.shengyu.module.system.controller.app.im.vo.sticker.AppImStickerSortReqVO;
import com.shengyu.module.system.controller.app.im.vo.sticker.AppImStickerUploadReqVO;

public interface ImStickerService {

    AppImStickerListRespVO getStickerList(Long userId);

    AppImStickerRespVO uploadSticker(Long userId, AppImStickerUploadReqVO reqVO);

    AppImStickerRespVO collectSticker(Long userId, AppImStickerCollectReqVO reqVO);

    void removeSticker(Long userId, Long stickerId);

    void sortStickers(Long userId, AppImStickerSortReqVO reqVO);

    void recordRecentUse(Long userId, Long stickerId);
}
