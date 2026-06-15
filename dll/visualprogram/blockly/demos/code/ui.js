var UILLRobot = new function() {
	this.width = $(window).width() * 0.8;
	this.height = 172;

	this.close = function() {
		$('.win iframe').fadeOut();
		$('.win').fadeOut("fast");
		setTimeout(function() {
			$('.win iframe').remove();
			$('.win').remove();
			if (window.Code && typeof Code.scheduleLayoutRefresh_ === 'function') {
				Code.scheduleLayoutRefresh_();
			}
		}, 200);
	};

	this.open = function(width, height, title, url, closed) {
		this._close = function() {
			this.close();
			if($.isFunction(closed)) closed();
		};
		var html = '<div class="win"><div class="mask-layer"></div><div class="window-panel"><iframe class="title-panel" frameborder="0" marginheight="0" marginwidth="0" scrolling="no"></iframe><div class="title"><h3></h3></div><a href="javascript:void(0)" onclick="UILLRobot._close();" class="close-btn" title="关闭">×</a><iframe class="body-panel" frameborder="0" marginheight="0" marginwidth="0" scrolling="auto" src=""></iframe></div></div>';
		var jq = $(html);
		jq.find(".window-panel").height(UILLRobot.height).width(UILLRobot.width).css("margin-left", -UILLRobot.width / 2).css("margin-top", -UILLRobot.height);
		jq.find(".title").find(":header").html(title);
		jq.find(".body-panel").height(height - 36).attr("src", url);
		jq.appendTo('body').fadeIn("fast");
		$(".win .window-panel").focus();
	};

	function messageBox(html, title, message, type) {
		var jq = $(html);
		if(type == "toast") {
			jq.find(".window-panel").width(message.length * 20).css("margin-left", -message.length * 20 / 2).css("margin-top", -UILLRobot.height / 2);
		} else {
			jq.find(".window-panel").width(UILLRobot.width).css("margin-left", -UILLRobot.width / 2).css("margin-top", -UILLRobot.height / 2 - 36);
		}
		if(valempty(title)) {
			jq.find(".title").remove();
			jq.find(".window-panel .body-panel").css("border-radius", "4px");
		} else {
			jq.find(".title").find(":header").html(title);
		}
		jq.find(".alertcontent").html(message.replace('\r\n', '<br/>'));
		jq.appendTo('body').fadeIn("fast");
		$(".win .w-btn:first").focus();
	}

	this.confirm = function(title, message, selected) {
		this._close = function(flag) {
			selected(flag);
			if (flag) {
				$('.win').last().find('iframe').remove();
				$('.win').last().remove();
			} else {
				UILLRobot.close();
			}
		};

		var html = '<div class="win"><div class="mask-layer"></div><div class="window-panel"><iframe class="title-panel" frameborder="0" marginheight="0" marginwidth="0" scrolling="no"></iframe><div class="title"><h3></h3></div><div class="body-panel"><p class="alertcontent"></p><p class="btns"><button class="w-btn" tabindex="1" onclick="UILLRobot._close(true);">确定</button><button class="w-btn" onclick="UILLRobot._close(false);">取消</button></p></div></div></div>';
		messageBox(html, title, message);
	};

	this.alert = function(title, message, ico) {
		var icon = "";
		if(!valempty(ico)) {
			icon = '<p class="btns" style="margin-bottom:-15px;"><img width="70px" height="70px" src="images/' + ico + '.png"></p>';
		}
		var html = '<div class="win"><div class="mask-layer"></div><div class="window-panel"><iframe class="title-panel" frameborder="0" marginheight="0" marginwidth="0" scrolling="no"></iframe><div class="title"><h3></h3></div><div class="body-panel">' + icon + '<p class="alertcontent"></p><p class="btns"><button class="w-btn" tabindex="1" onclick="UILLRobot.close();">确定</button></p></div></div></div>';
		messageBox(html, title, message);
	}

	this.toast = function(message, time) {
		var html = '<div class="win"><div class="window-panel"><iframe class="title-panel" frameborder="0" marginheight="0" marginwidth="0" scrolling="no"></iframe><div class="body-panel toast-panel"><p class="alertcontent toast-content"></p></div></div></div>';
		messageBox(html, "", message, "toast");
		setTimeout(function() {
          UILLRobot.close();
		}, time || 3000);
	}
};

function valempty(str) {
	if(str == "null" || str == null || str == "" || str == "undefined" || str == undefined || str == 0) {
		return true;
	} else {
		return false;
	}
}