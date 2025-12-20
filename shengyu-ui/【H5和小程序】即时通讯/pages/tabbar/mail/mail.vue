<template>
	<view>
		
		<!-- 导航栏 -->
		<free-nav-bar title="通讯录"></free-nav-bar>
		
		<!-- 通讯录列表 -->
		<scroll-view scroll-y="true" :style="'height:'+scrollHeight+'px;'"
		:scroll-into-view="scrollInto">
			<free-list-item v-for="(item,index) in topList" 
			:key="item.id"
			:title="item.title" :cover="item.cover" 
			:showRight="item.id === 'friend' && applyCount > 0"
			@click="navigate(item.path)">
				<view slot="right">
					<free-badge v-if="applyCount > 0" :value="applyCount"></free-badge>
				</view>
			</free-list-item>
			
			<view v-for="(item,index) in list" :key="index"
			:id="'item-'+item.title">
				<view v-if="item.list.length" 
				class="py-2 px-3 border-bottom bg-light">
					<text class="font-md text-dark">{{item.title}}</text>
				</view>
				<free-list-item v-for="(item2,index2) in item.list" 
				:key="index2" :title="item2.name" 
				:cover="item2.avatar ? item2.avatar : '/static/images/userpic.png'"
				@click="navigate('mail/user-base/user-base?user_id='+item2.user_id)"></free-list-item>
			</view>
		</scroll-view>
		
		<!-- 侧边导航条 -->
		<view class="position-fixed right-0 bottom-0 bg-light flex flex-column" :style="'top:'+top+'px;'" style="width: 50rpx;" @touchstart="touchstart" @touchmove="touchmove" @touchend="touchend">
			<view class="flex-1 flex align-center justify-center"
			v-for="(item,index) in list" :key="index">
				<text class="font-sm text-muted">{{item.title}}</text>
			</view>
		</view>

		<view class="position-fixed rounded-circle bg-light border flex align-center justify-center" v-if="current"
		style="width: 150rpx;height: 150rpx;left: 300rpx;"
		:style="'top:'+modalTop+'px;'">
			<text class="font-lg">{{current}}</text>
		</view>

	</view>
</template>

<script>
	import freeNavBar from "@/components/free-ui/free-nav-bar.vue"
	import freeListItem from "@/components/free-ui/free-list-item.vue"
	import freeBadge from "@/components/free-ui/free-badge.vue"
	import auth from '@/common/mixin/auth.js';
	import { mapState } from 'vuex'
	export default {
		mixins:[auth],
		components: {
			freeNavBar,
			freeListItem,
			freeBadge
		},
		data() {
			return {
				topList:[
					{
						id:"friend",
						title:"新的朋友",
						cover:"/static/images/mail/friend.png",
						path:"mail/apply-list/apply-list"
					},
					{
						id:"group",
						title:"群聊",
						cover:"/static/images/mail/group.png",
						path:"mail/group-list/group-list"
					},
					{
						id:"tag",
						title:"标签",
						cover:"/static/images/mail/tag.png",
						path:"mail/tag-list/tag-list"
					}
				],
				
				top:0,
				scrollHeight:0,
				scrollInto:'',
				current:''
			}
		},
		onLoad() {
			let res = uni.getSystemInfoSync()
			this.top = res.statusBarHeight + uni.upx2px(90)
			this.scrollHeight = res.windowHeight - this.top
			
			this.$store.dispatch('getMailList')
		},
		computed: {
			...mapState({
				applyCount:state=>state.user.apply.count,
				list:state=>state.user.mailList
			}),
			modalTop(){
				return (this.scrollHeight - uni.upx2px(150)) / 2
			},
			// 每个索引的高度
			itemHeight() {
				let count = this.list.length
				if(count < 1){
					return 0
				}
				return this.scrollHeight /  count
			}
		},
		methods: {
			touchstart(e){
				this.changeScrollInto(e)
			},
			touchmove(e){
				this.changeScrollInto(e)
			},
			touchend(e){
				this.current = ''
			},
			// 联动
			changeScrollInto(e){
				let Y = e.touches[0].pageY
				// #ifdef MP
				Y = Y - this.top
				// #endif
				let index = Math.floor(Y / this.itemHeight)
				let item = this.list[index]
				if(item){
					this.scrollInto = 'item-'+item.letter
					this.current = item.letter
				}
			}
		}
	}
</script>

<style>

</style>
