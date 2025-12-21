<template>
	<view class="page">
		<!-- 导航栏 -->
		<free-nav-bar title="我的设置" showBack :showRight="false"></free-nav-bar>
		<!-- 退出登录 -->
		<free-divider></free-divider>
		<view class="py-3 flex align-center justify-center bg-white"
		hover-class="bg-light" @click="logout">
			<text class="font-md text-primary">退出登录</text>
		</view>
	</view>
</template>

<script>
	import freeNavBar from "@/components/free-ui/free-nav-bar.vue"
	import freeDivider from "@/components/free-ui/free-divider.vue"
	import $H from '@/common/free-lib/request.js';
	export default {
		components: {
			freeNavBar,
			freeDivider
		},
		data() {
			return {
				
			}
		},
		methods: {
			logout(){
				$H.post('/logout').then(res=>{
					uni.showToast({
						title: '退出登录成功',
						icon: 'none'
					});
					this.$store.dispatch('logout')
				})
			}
		}
	}
</script>

<style>

</style>
