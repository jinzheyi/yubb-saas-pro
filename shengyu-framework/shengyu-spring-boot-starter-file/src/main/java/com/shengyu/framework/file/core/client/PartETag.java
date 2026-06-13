package com.shengyu.framework.file.core.client;

import java.util.Objects;

/**
 * 分片上传的分片标识
 *
 * @author 圣钰科技
 */
public class PartETag {

    /**
     * 分片号，从 1 开始
     */
    private final int partNumber;

    /**
     * 分片上传成功后返回的 ETag
     */
    private final String etag;

    public PartETag(int partNumber, String etag) {
        this.partNumber = partNumber;
        this.etag = etag;
    }

    public int getPartNumber() {
        return partNumber;
    }

    public String getEtag() {
        return etag;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        PartETag partETag = (PartETag) o;
        return partNumber == partETag.partNumber && Objects.equals(etag, partETag.etag);
    }

    @Override
    public int hashCode() {
        return Objects.hash(partNumber, etag);
    }

    @Override
    public String toString() {
        return "PartETag{" +
                "partNumber=" + partNumber +
                ", etag='" + etag + '\'' +
                '}';
    }
}
