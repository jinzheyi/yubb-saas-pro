<template>
	<view class="page">
		<!-- 导航栏 -->
		<free-nav-bar title="发现"></free-nav-bar>
		
		<free-list-item title="朋友圈" showRight @click="openMoments">
			<text slot="icon" class="iconfont font-lg py-1">&#xe667;</text>
			<view slot="right" class="p-1">
				<view class="position-relative" v-if="!notice.num && notice.user_id">
				<free-avater 
				:src="notice.avatar || '/static/images/userpic.png'" 
				size="55"></free-avater>
				<text class="rounded-circle bg-danger position-absolute" style="width: 20rpx;height: 20rpx;top: 0;right: 0;"></text>
				</view>
				<free-badge v-if="notice.num" :value="notice.num"></free-badge>
			</view>
		</free-list-item>
		<free-divider></free-divider>
		<free-list-item title="扫一扫" showRight>
			<text slot="icon" class="iconfont font-lg py-1">&#xe86d;</text>
		</free-list-item>
		<free-list-item title="摇一摇" showRight>
			<text slot="icon" class="iconfont font-lg py-1">&#xe63d;</text>
		</free-list-item>
		<free-divider></free-divider>
		<free-list-item title="看一看" showRight>
			<text slot="icon" class="iconfont font-lg py-1">&#xe610;</text>
		</free-list-item>
		<free-list-item title="搜一搜" showRight>
			<text slot="icon" class="iconfont font-lg py-1">&#xe611;</text>
		</free-list-item>
		<free-divider></free-divider>
		<free-list-item title="购物" showRight>
			<text slot="icon" class="iconfont font-lg py-1">&#xe658;</text>
		</free-list-item>
		
	</view>
</template>

<script>
	import freeNavBar from "@/components/free-ui/free-nav-bar.vue"
	import freeListItem from "@/components/free-ui/free-list-item.vue"
	import freeAvater from "@/components/free-ui/free-avater.vue"
	import freeDivider from "@/components/free-ui/free-divider.vue"
	import auth from '@/common/mixin/auth.js';
	import { mapState } from 'vuex'
	import freeBadge from '@/components/free-ui/free-badge.vue';
	export default {
		mixins:[auth],
		components: {
			freeNavBar,
			freeListItem,
			freeAvater,
			freeDivider,
			freeBadge
		},
		data() {
			return {
				
			}
		},
		computed: {
			...mapState({
				notice:state=>state.user.notice,
				chat:state=>state.user.chat
			})
		},
		methods: {
			// 打开朋友圈
			openMoments(){
				uni.navigateTo({
					url: '../../find/moments/moments',
				});
				this.chat.readMoments()
			}
			
		}
	}
</script>

<style>

</style>
