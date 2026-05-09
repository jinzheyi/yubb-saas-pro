package com.shengyu.module.infra.service.file;

import cn.hutool.core.io.FileUtil;
import cn.hutool.core.util.StrUtil;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.jcodec.api.FrameGrab;
import org.jcodec.api.JCodecException;
import org.jcodec.common.model.Picture;
import org.jcodec.scale.AWTUtil;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;

@Service
@Slf4j
public class VideoThumbnailService {

    private static final int MAX_WIDTH = 480;

    public GeneratedThumbnail generate(byte[] videoBytes, String sourceName) {
        if (videoBytes == null || videoBytes.length == 0) {
            return null;
        }
        File tempFile = null;
        try {
            String suffix = resolveSuffix(sourceName);
            tempFile = Files.createTempFile("im-video-thumb-", suffix).toFile();
            Files.write(tempFile.toPath(), videoBytes);
            Picture picture = FrameGrab.getFrameAtSec(tempFile, 0);
            if (picture == null) {
                return null;
            }
            BufferedImage rawImage = AWTUtil.toBufferedImage(picture);
            BufferedImage normalized = normalizeImage(rawImage);
            ByteArrayOutputStream output = new ByteArrayOutputStream();
            ImageIO.write(normalized, "jpg", output);
            return new GeneratedThumbnail(
                    output.toByteArray(),
                    buildThumbnailFileName(sourceName),
                    "image/jpeg"
            );
        } catch (IOException | JCodecException e) {
            log.warn("[VideoThumbnailService] generate thumbnail failed, sourceName={}", sourceName, e);
            return null;
        } finally {
            if (tempFile != null && tempFile.exists() && !tempFile.delete()) {
                log.debug("[VideoThumbnailService] failed to delete temp file: {}", tempFile.getAbsolutePath());
            }
        }
    }

    private BufferedImage normalizeImage(BufferedImage source) {
        if (source == null) {
            return null;
        }
        int sourceWidth = Math.max(source.getWidth(), 1);
        int sourceHeight = Math.max(source.getHeight(), 1);
        int targetWidth = sourceWidth;
        int targetHeight = sourceHeight;
        if (sourceWidth > MAX_WIDTH) {
            targetWidth = MAX_WIDTH;
            targetHeight = Math.max(1, (int) Math.round((double) sourceHeight * MAX_WIDTH / sourceWidth));
        }
        BufferedImage target = new BufferedImage(targetWidth, targetHeight, BufferedImage.TYPE_INT_RGB);
        Graphics2D graphics = target.createGraphics();
        try {
            graphics.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
            graphics.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
            graphics.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            graphics.drawImage(source, 0, 0, targetWidth, targetHeight, null);
        } finally {
            graphics.dispose();
        }
        return target;
    }

    private String buildThumbnailFileName(String sourceName) {
        String normalized = StrUtil.blankToDefault(sourceName, "video");
        String mainName = FileUtil.mainName(normalized);
        if (StrUtil.isBlank(mainName)) {
            mainName = "video";
        }
        return mainName + "_thumb.jpg";
    }

    private String resolveSuffix(String sourceName) {
        String ext = FileUtil.extName(StrUtil.blankToDefault(sourceName, ""));
        return StrUtil.isNotBlank(ext) ? "." + ext : ".mp4";
    }

    @Data
    @AllArgsConstructor
    public static class GeneratedThumbnail {
        private byte[] content;
        private String fileName;
        private String mimeType;
    }
}
