package com.shengyu.framework.common.util.qrcode;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.EncodeHintType;
import com.google.zxing.WriterException;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel;
import lombok.extern.slf4j.Slf4j;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

/**
 * 二维码工具类
 * 基于 ZXing 实现二维码生成
 *
 * @author 圣钰科技
 */
@Slf4j
public class QRCodeUtil {

    /**
     * 默认二维码宽度
     */
    private static final int DEFAULT_WIDTH = 300;

    /**
     * 默认二维码高度
     */
    private static final int DEFAULT_HEIGHT = 300;

    /**
     * 默认字符编码
     */
    private static final String DEFAULT_CHARSET = "UTF-8";

    /**
     * 默认图片格式
     */
    private static final String DEFAULT_FORMAT = "PNG";

    /**
     * 生成二维码（默认尺寸 300x300）
     *
     * @param content 二维码内容
     * @return BufferedImage 二维码图片
     */
    public static BufferedImage generateQRCode(String content) {
        return generateQRCode(content, DEFAULT_WIDTH, DEFAULT_HEIGHT);
    }

    /**
     * 生成二维码（指定尺寸）
     *
     * @param content 二维码内容
     * @param width   宽度
     * @param height  高度
     * @return BufferedImage 二维码图片
     */
    public static BufferedImage generateQRCode(String content, int width, int height) {
        try {
            // 配置参数
            Map<EncodeHintType, Object> hints = new HashMap<>();
            hints.put(EncodeHintType.CHARACTER_SET, DEFAULT_CHARSET);
            hints.put(EncodeHintType.ERROR_CORRECTION, ErrorCorrectionLevel.H); // 容错级别：H（高）
            hints.put(EncodeHintType.MARGIN, 1); // 边距

            // 生成二维码矩阵
            QRCodeWriter qrCodeWriter = new QRCodeWriter();
            BitMatrix bitMatrix = qrCodeWriter.encode(content, BarcodeFormat.QR_CODE, width, height, hints);

            // 转换为图片
            return MatrixToImageWriter.toBufferedImage(bitMatrix);
        } catch (WriterException e) {
            log.error("[QRCodeUtil] 生成二维码失败, content: {}", content, e);
            throw new RuntimeException("生成二维码失败", e);
        }
    }

    /**
     * 生成二维码字节数组
     *
     * @param content 二维码内容
     * @return byte[] 二维码图片字节数组
     */
    public static byte[] generateQRCodeBytes(String content) {
        return generateQRCodeBytes(content, DEFAULT_WIDTH, DEFAULT_HEIGHT);
    }

    /**
     * 生成二维码字节数组（指定尺寸）
     *
     * @param content 二维码内容
     * @param width   宽度
     * @param height  高度
     * @return byte[] 二维码图片字节数组
     */
    public static byte[] generateQRCodeBytes(String content, int width, int height) {
        try {
            BufferedImage image = generateQRCode(content, width, height);
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            ImageIO.write(image, DEFAULT_FORMAT, baos);
            return baos.toByteArray();
        } catch (IOException e) {
            log.error("[QRCodeUtil] 生成二维码字节数组失败, content: {}", content, e);
            throw new RuntimeException("生成二维码字节数组失败", e);
        }
    }

    /**
     * 生成二维码（带Logo）
     * 注意：此方法需要额外实现 Logo 叠加逻辑
     *
     * @param content  二维码内容
     * @param logoPath Logo 图片路径
     * @return BufferedImage 二维码图片
     */
    public static BufferedImage generateQRCodeWithLogo(String content, String logoPath) {
        // TODO: 实现带 Logo 的二维码生成
        // 1. 生成基础二维码
        // 2. 读取 Logo 图片
        // 3. 将 Logo 叠加到二维码中心
        // 4. 返回合成后的图片
        throw new UnsupportedOperationException("带 Logo 的二维码生成功能待实现");
    }
}
