<script lang="ts" name="PlugApp" setup>

const { push } = useRouter()

// 跳转应用市场
const goPluginMarket = () => {
  push({
    name: 'PluginMarket'
  })
}
</script>
<template>
  <div class="message">
    <ElPopover :width="400" placement="bottom" trigger="click">
      <template #reference>
        <ElBadge class="item">
          <Icon :size="18" class="cursor-pointer" icon="ep:goods" @click="goPluginMarket" />
        </ElBadge>
      </template>
    </ElPopover>
  </div>
</template>
<style lang="scss" scoped>
.message-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 260px;
  line-height: 45px;
}

.message-list {
  display: flex;
  flex-direction: column;

  .message-item {
    display: flex;
    align-items: center;
    padding: 20px 0;
    border-bottom: 1px solid var(--el-border-color-light);

    &:last-child {
      border: none;
    }

    .message-icon {
      width: 40px;
      height: 40px;
      margin: 0 20px 0 5px;
    }

    .message-content {
      display: flex;
      flex-direction: column;

      .message-title {
        margin-bottom: 5px;
      }

      .message-date {
        font-size: 12px;
        color: var(--el-text-color-secondary);
      }
    }
  }
}
</style>
