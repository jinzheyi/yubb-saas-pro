<template>
	<view>
		<!-- 导航栏 -->
		<free-nav-bar title="选择" showBack :showRight="true">
			<free-main-button :name="muliSelect ? '发送 ('+selectCount+')' : '多选'" slot="right" @click="handleNavBarBtn"></free-main-button>
		</free-nav-bar>
		<!-- 搜索框 -->
		<view class="p-3 bg-light position-fixed left-0 right-0"
		:style="'top:'+top+'px;'">
			<input type="text" v-model="keyword" placeholder="搜索" class="bg-white rounded" placeholder-class="text-center" style="height: 80rpx;"/>
		</view>
		<view style="height: 140rpx;"></view>
		<!-- 联系人列表 -->
		<free-list-item title="更多联系人" :showLeftIcon="false" :border="false" @click="openMail"></free-list-item>
		<view class="px-2 py-1 bg-light">
			<text class="font-sm text-muted">{{keyword ? '搜索结果' :'最近联系人'}}</text>
		</view>
		
		<free-list-item :title="item.username" 
		v-for="(item,index) in allList"
		:key="index" :cover="item.avatar" showRight 
		:showRightIcon="false" @click="selectItem(item)">
			<view v-if="muliSelect" slot="right" 
			style="width: 40rpx;height: 40rpx;"
			class="border rounded-circle flex align-center justify-center">
				<view v-if="item.checked" style="width: 30rpx;height: 30rpx;"
				class="main-bg-color rounded-circle"></view>
			</view>
		</free-list-item>
		
		<view v-if="keyword !== '' && searchList.length === 0" 
		class="flex align-center justify-center" 
		style="height: 100rpx;">
			<text class="font text-light-muted">暂无搜索结果</text>
		</view>
		
		<free-confirm ref="confirm" title="发送给：">
			<scroll-view scroll-x="true" class="flex"
			:show-scrollbar="false">
				<view class="mr-1" v-for="i in 10" :key="i">
					<free-avater src="/static/images/mail/friend.png" size="60"></free-avater>
				</view>
			</scroll-view>
			<view class="my-3 bg-light rounded p-2">
				<text class="font text-light-muted">[个人名片] 昵称</text>
			</view>
			<input type="text" class="border-bottom font-md" style="height: 60rpx;" placeholder="给朋友留言" />
		</free-confirm>
		
	</view>
</template>

<script>
	import freeNavBar from '@/components/free-ui/free-nav-bar.vue';
	import freeMainButton from '@/components/free-ui/free-main-button.vue';
	import freeListItem from '@/components/free-ui/free-list-item.vue';
	import freeConfirm from '@/components/free-ui/free-confirm.vue';
	import freeAvater from '@/components/free-ui/free-avater.vue';
	export default {
		components: {
			freeNavBar,
			freeMainButton,
			freeListItem,
			freeConfirm,
			freeAvater
		},
		data() {
			return {
				keyword:"",
				muliSelect:false,
				top:0,
				list:[{
					username:"昵称1",
					avatar:"/static/images/mail/friend.png",
					checked:false
				},{
					username:"昵称2",
					avatar:"/static/images/mail/friend.png",
					checked:false
				},{
					username:"昵称3",
					avatar:"/static/images/mail/friend.png",
					checked:false
				},{
					username:"昵称4",
					avatar:"/static/images/mail/friend.png",
					checked:false
				},{
					username:"昵称5",
					avatar:"/static/images/mail/friend.png",
					checked:false
				},{
					username:"昵称6",
					avatar:"/static/images/mail/friend.png",
					checked:false
				},{
					username:"昵称7",
					avatar:"/static/images/mail/friend.png",
					checked:false
				},{
					username:"昵称8",
					avatar:"/static/images/mail/friend.png",
					checked:false
				},{
					username:"昵称9",
					avatar:"/static/images/mail/friend.png",
					checked:false
				},{
					username:"昵称10",
					avatar:"/static/images/mail/friend.png",
					checked:false
				},{
					username:"昵称11",
					avatar:"/static/images/mail/friend.png",
					checked:false
				},{
					username:"昵称12",
					avatar:"/static/images/mail/friend.png",
					checked:false
				}]
			}
		},
		onLoad() {
			let res = uni.getSystemInfoSync()
			this.top = res.statusBarHeight + uni.upx2px(90)
		},
		computed: {
			// 最终列表
			allList(){
				return this.keyword==='' ? this.list : this.searchList
			},
			// 搜索结果列表
			searchList(){
				if(this.keyword === ''){
					return []
				}
				return this.list.filter(item=>{
					return item.username.indexOf(this.keyword) !== -1
				})
			},
			// 选中列表
			selectList() {
				return this.list.filter(item=>item.checked) 
			},
			// 选中数量
			selectCount(){
				return this.selectList.length
			}
		},
		methods: {
			// 点击导航栏按钮事件
			handleNavBarBtn(){
				// 切换成多选状态
				if(!this.muliSelect){
					return this.muliSelect = true
				}
				// 发送
				console.log('发送');
			},
			// 选中/取消选中 | 发送
			selectItem(item){
				// 选中/取消选中
				if(this.muliSelect){
					if(!item.checked && this.selectCount === 9){ 
						// 选中|限制选中数量
						return uni.showToast({
							title: '最多选中 9 个',
							icon: 'none'
						});
					}
					return item.checked = !item.checked
				}
				// 发送
				this.$refs.confirm.show((close)=>{
					console.log('点击了确定');
					close()
				})
			},
			// 更多联系人
			openMail(){
				uni.navigateTo({
					url: '../mail/mail'
				});
			}
		}
	}
</script>

<style>

</style>
