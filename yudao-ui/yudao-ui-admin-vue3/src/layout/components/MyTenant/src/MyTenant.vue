<script lang="ts" setup>
import { formatDate } from '@/utils/formatTime'
import * as UserApi from '@/api/system/user'
import * as LoginApi from "@/api/login";
import * as authUtil from "@/utils/auth";
import { usePermissionStore } from '@/store/modules/permission'
import {useUserStore} from "@/store/modules/user";
import {useTagsViewStore} from "@/store/modules/tagsView";

defineOptions({ name: 'MyTenant' })

const activeName = ref('myTenant')
const list = ref<any[]>([]) // 租户列表
const redirect = ref<string>('')
const { push } = useRouter()
const permissionStore = usePermissionStore()
const userStore = useUserStore()
const tagsViewStore = useTagsViewStore()

const getList = async () => {
  list.value = await UserApi.getMyTenantList()
}

// 跳转到目标租户
const toTenant = async (id: number) => {
  const res = await LoginApi.toTenant(id)
  if (!res) {
    return
  }
  //推出登錄的一些操作
  await userStore.loginToTenantOut()
  tagsViewStore.delAllViews()
  authUtil.setToken(res)
  if (!redirect.value) {
    redirect.value = '/'
  }
  push({ path: redirect.value || permissionStore.addRouters[0].path })
  location.reload();
}

</script>
<template>
  <div class="message">
    <ElPopover :width="400" placement="bottom" trigger="click">
      <template #reference>
        <ElBadge class="item">
          <Icon :size="18" class="cursor-pointer" icon="ep:office-building" @click="getList" />
        </ElBadge>
      </template>
      <ElTabs v-model="activeName">
        <ElTabPane label="我的企业/租户" name="myTenant">
          <el-scrollbar class="message-list">
            <template v-for="item in list" :key="item.id">
              <div class="message-item" @click="toTenant(item.id)">
<!--                <img alt="" class="message-icon" src="@/assets/imgs/avatar.gif" />-->
                <div class="message-content">
                  <span class="message-title">
                    {{ item.tenantName }}【{{ item.status }}】
                  </span>
                  <span class="message-date">
                    最后登录时间：{{ formatDate(item.loginDate) }}
                  </span>
                </div>
              </div>
            </template>
          </el-scrollbar>
        </ElTabPane>
      </ElTabs>
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
  height: 400px;
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
