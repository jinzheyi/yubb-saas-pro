<template>
	<view class="page">
		<!-- 导航栏 -->
		<free-nav-bar title="个人资料" showBack :showRight="false"></free-nav-bar>
		<free-list-item title="头像" showRight :showLeftIcon="false"
		@click="update('avatar')">
			<free-avater slot="right" :src="user.avatar"></free-avater>
		</free-list-item>
		<free-list-item title="昵称" showRight :showLeftIcon="false"
		@click="update('nickname')">
			<text slot="right" class="font text-muted">{{user.nickname}}</text>
		</free-list-item>
		<free-list-item title="账号" showRight :showLeftIcon="false">
			<text slot="right" class="font text-muted">{{user.username}}</text>
		</free-list-item>
		<free-list-item title="二维码名片" showRight :showLeftIcon="false"
		@click="openCode">
			<text slot="right" class="iconfont font-md">&#xe647;</text>
		</free-list-item>
		
		<free-confirm ref="confirm" :title="confirmTitle">
			<input type="text" v-model="confirmText" :placeholder="placeholder" class="border-bottom font-md"/>
		</free-confirm>
		
	</view>
</template>

<script>
	import freeNavBar from "@/components/free-ui/free-nav-bar.vue"
	import freeAvater from '@/components/free-ui/free-avater.vue';
	import freeListItem from "@/components/free-ui/free-list-item.vue"
	import freeConfirm from '@/components/free-ui/free-confirm.vue';
	import { mapState } from 'vuex'
	import $H from '@/common/free-lib/request.js';
	export default {
		components: {
			freeNavBar,
			freeAvater,
			freeListItem,
			freeConfirm
		},
		data() {
			return {
				confirmText:"",
				confirmType:""
			}
		},
		computed: {
			...mapState({
				user:state=>state.user.user
			}),
			confirmTitle() {
				return this.confirmType == 'username' ? '修改账号' :'修改昵称' 
			},
			placeholder(){
				return this.confirmType == 'username' ? '输入账号' :'输入昵称' 
			}
		},
		methods: {
			update(key){
				switch (key){
					case 'avatar':
					uni.chooseImage({
						count:1,
						sizeType: ['compressed'],
						success: (res) => {
							// 上传
							$H.upload('/upload',{
								filePath:res.tempFilePaths[0]
							}).then(url=>{
								$H.post('/user/update',{
									avatar:url,
									nickname:this.user.nickname
								}).then(res=>{
									uni.showToast({
										title: '修改头像成功',
										icon: 'none'
									});
									this.$store.commit('updateUser',{
										k:'avatar',
										v:url
									})
								})
							})
						}
					})
						break;
					default:
					this.confirmType = key
					this.confirmText = this.user[key]
					this.$refs.confirm.show((close)=>{
						if(this.confirmText === ''){
							return uni.showToast({
								title: '不能为空',
								icon: 'none'
							});
						}
						$H.post('/user/update',{
							avatar:this.user.avatar,
							nickname:this.confirmText
						}).then(res=>{
							this.$store.commit('updateUser',{
								k:'nickname',
								v:this.confirmText
							})
							uni.showToast({
								title: '修改成功',
								icon: 'none'
							});
						})
						close()
					})
						break;
				}
			},
			openCode(){
				uni.navigateTo({
					url: '../code/code?params='+encodeURIComponent(JSON.stringify({
						id:this.user.id,
						name:this.user.nickname || this.user.username,
						avatar:this.user.avatar
					}))+'&type=user',
				});
			}
		}
	}
</script>

<style>

</style>
