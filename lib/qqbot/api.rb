require 'uri'
require 'json'
require 'fileutils'

module QQBot
  class Api

    def initialize(client, options = {})
      @client = client
      @options = options
      @msg_id = 1_000_000
    end

    def self.hash(uin, ptwebqq)
      n = Array.new(4, 0)

      for i in (0...ptwebqq.size)
        n[i % 4] ^= ptwebqq[i].ord
      end

      u = ['EC', 'OK']

      v = Array.new(4)
      v[0] = uin >> 24 & 255 ^ u[0][0].ord;
      v[1] = uin >> 16 & 255 ^ u[0][1].ord;
      v[2] = uin >> 8 & 255 ^ u[1][0].ord;
      v[3] = uin & 255 ^ u[1][1].ord;

      u = Array.new(8)
      for i in (0...8)
        u[i] = i.odd? ? v[i >> 1] : n[i >> 1]
      end

      n = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F']

      v = ''

      u.each do |i|
        v << n[(i >> 4) & 15]
        v << n[i & 15]
      end

      v
    end

    def poll
      uri = URI('http://d1.web2.qq.com/channel/poll2')

      r = JSON.generate(
        ptwebqq: @options[:ptwebqq],
        clientid: 53999199,
        psessionid: @options[:psessionid],
        key: ''
      )

      begin
        code, body = @client.post(uri, 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2', r: r)
      rescue
        retry
      end

      if code == '200'
        json = JSON.parse body
        if json['retcode'] == 0
          return json['result']
        else
          QQBot::LOGGER.info "获取消息失败 返回码 #{json['retcode']}"
        end
      else
        QQBot::LOGGER.info "请求失败，返回码 #{code}"
      end
    end

    def get_group_list
        uri = URI('http://s.web2.qq.com/api/get_group_name_list_mask2')

        r = JSON.generate(
          vfwebqq: @options[:vfwebqq],
          hash: hash
        )

        code, body = @client.post(uri, 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2', r: r)

        if code == '200'
          json = JSON.parse body
          if json['retcode'] == 0
            return json['result']
          else
            QQBot::LOGGER.info "获取群列表失败 返回码 #{json['retcode']}"
          end
        else
          QQBot::LOGGER.info "请求失败，返回码 #{code}"
        end
    end

    def hash
      self.class.hash(@options[:uin], @options[:ptwebqq])
    end

    def get_friend_list
        uri = URI('http://s.web2.qq.com/api/get_user_friends2')

        r = JSON.generate(
          vfwebqq: @options[:vfwebqq],
          hash: hash
        )

        code, body = @client.post(uri, 'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1', r: r)

        if code == '200'
          json = JSON.parse body
          if json['retcode'] == 0
            return json['result']
          else
            QQBot::LOGGER.info "获取好友列表失败 返回码 #{json['retcode']}"
          end
        else
          QQBot::LOGGER.info "请求失败，返回码 #{code}"
        end
    end

    def get_discuss_list
        uri = URI('http://s.web2.qq.com/api/get_discus_list')
        uri.query =
          URI.encode_www_form(
            clientid: 53999199,
            psessionid: @options[:psessionid],
            vfwebqq: @options[:vfwebqq],
            t: 0.1
          )

        code, body = @client.get(uri, 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2')

        if code == '200'
          json = JSON.parse body
          if json['retcode'] == 0
            return json['result']
          else
            QQBot::LOGGER.info "获取群列表失败 返回码 #{json['retcode']}"
          end
        else
          QQBot::LOGGER.info "请求失败，返回码 #{code}"
        end
    end

    def send_to_friend(friend_id, content)
      uri = URI('http://d1.web2.qq.com/channel/send_buddy_msg2')

      r = JSON.generate(
        to: friend_id,
        content: build_message(content),
        face: 522,
        clientid: 53999199,
        msg_id: msg_id,
        psessionid: @options[:psessionid]
      )

      code, body = @client.post(uri, 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2', r: r)

      if code == '200'
        json = JSON.parse body
        if json['errCode'] == 0
          QQBot::LOGGER.info '发送成功'
          return true
        else
          QQBot::LOGGER.info "发送失败 返回码 #{json['retcode']}"
        end
      else
        QQBot::LOGGER.info "请求失败，返回码 #{code}"
      end
      return false
    end

    def send_to_group(group_id, content)
      uri = URI('http://d1.web2.qq.com/channel/send_qun_msg2')

      r = JSON.generate(
        group_uin: group_id,
        content: build_message(content),
        face: 522,
        clientid: 53999199,
        msg_id: msg_id,
        psessionid: @options[:psessionid]
      )

      code, body = @client.post(uri, 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2', r: r)

      if code == '200'
        json = JSON.parse body
        if json['errCode'] == 0
          QQBot::LOGGER.info '发送成功'
          return true
        else
          QQBot::LOGGER.info "发送失败 返回码 #{json['retcode']}"
        end
      else
        QQBot::LOGGER.info "请求失败，返回码 #{code}"
      end
      return false
    end

    def send_to_discuss(discuss_id, content)
      uri = URI('http://d1.web2.qq.com/channel/send_discu_msg2')

      r = JSON.generate(
        did: discuss_id,
        content: build_message(content),
        face: 522,
        clientid: 53999199,
        msg_id: msg_id,
        psessionid: @options[:psessionid]
      )

      code, body = @client.post(uri, 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2', r: r)

      if code == '200'
        json = JSON.parse body

      if json['errCode'] == 0
          QQBot::LOGGER.info '发送成功'
          return true
        else
          QQBot::LOGGER.info "发送失败 返回码 #{json['retcode']}"
        end
      else
        QQBot::LOGGER.info "请求失败，返回码 #{code}"
      end
      return false
    end

    def send_to_sess(sess_id, content)
      uri = URI('http://d1.web2.qq.com/channel/send_sess_msg2')

      r = JSON.generate(
        to: sess_id,
        content: build_message(content),
        face: 522,
        clientid: 53999199,
        msg_id: msg_id,
        psessionid: @options[:psessionid]
      )

      code, body = @client.post(uri, 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2', r: r)

      if code == '200'
        json = JSON.parse body

      if json['errCode'] == 0
          QQBot::LOGGER.info '发送成功'
          return true
        else
          QQBot::LOGGER.info "发送失败 返回码 #{json['retcode']}"
        end
      else
        QQBot::LOGGER.info "请求失败，返回码 #{code}"
      end
      return false
    end

    def get_account_info
      uri = URI('http://s.web2.qq.com/api/get_self_info2')
      uri.query =
        URI.encode_www_form(
          t: 0.1
        )

      code, body = @client.get(uri, 'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1')

      if code == '200'
        json = JSON.parse body
        if json['retcode'] == 0
          return json['result']
        else
          QQBot::LOGGER.info "获取当前用户信息失败 返回码 #{json['retcode']}"
        end
      else
        QQBot::LOGGER.info "请求失败，返回码 #{code}"
      end
    end

    def get_recent_list
      uri = URI('http://d1.web2.qq.com/channel/get_recent_list2')

      r = JSON.generate(
        vfwebqq: @options[:vfwebqq],
        clientid: 53999199,
        psessionid: ''
      )

      code, body = @client.post(uri, 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2', r: r)

      if code == '200'
        json = JSON.parse body
        if json['retcode'] == 0
          return json['result']
        else
          QQBot::LOGGER.info "获取当前用户信息失败 返回码 #{json['retcode']}"
        end
      else
        QQBot::LOGGER.info "请求失败，返回码 #{code}"
      end
    end

    def get_qq_by_id(id)
      uri = URI('http://s.web2.qq.com/api/get_friend_uin2')
      uri.query =
        URI.encode_www_form(
          tuin: id,
          type: 1,
          vfwebqq: @options[:vfwebqq],
          t: 0.1
        )

      code, body = @client.get(uri, 'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1')

      if code == '200'
        json = JSON.parse body
        if json['retcode'] == 0
          return json['result']
        else
          QQBot::LOGGER.info "获取QQ号失败 返回码 #{json['retcode']}"
        end
      else
        QQBot::LOGGER.info "请求失败，返回码 #{code}"
      end
    end

    def get_online_friends
      uri = URI('http://d1.web2.qq.com/channel/get_online_buddies2')
      uri.query =
        URI.encode_www_form(
          vfwebqq: @options[:vfwebqq],
          clientid: 53999199,
          psessionid: @options[:psessionid],
          t: 0.1
        )

      code, body = @client.get(uri, 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2')

      if code == '200'
        json = JSON.parse body
        if json['retcode'] == 0
          return json['result']
        else
          QQBot::LOGGER.info "获取在线好友失败 返回码 #{json['retcode']}"
        end
      else
        QQBot::LOGGER.info "请求失败，返回码 #{code}"
      end
    end

    def get_group_info(group_code)
      uri = URI('http://s.web2.qq.com/api/get_group_info_ext2')
      uri.query =
        URI.encode_www_form(
          gcode: group_code,
          vfwebqq: @options[:vfwebqq],
          t: 0.1
        )

      code, body = @client.get(uri, 'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1')

      if code == '200'
        json = JSON.parse body
        if json['retcode'] == 0
          return json['result']
        else
          QQBot::LOGGER.info "获取群信息失败 返回码 #{json['retcode']}"
        end
      else
        QQBot::LOGGER.info "请求失败，返回码 #{code}"
      end
    end

    def get_discuss_info(discuss_id)
      uri = URI('http://d1.web2.qq.com/channel/get_discu_info')
      uri.query =
        URI.encode_www_form(
          did: discuss_id,
          vfwebqq: @options[:vfwebqq],
          clientid: 53999199,
          psessionid: @options[:psessionid],
          t: 0.1
        )

      code, body = @client.get(uri, 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2')

      if code == '200'
        json = JSON.parse body
        if json['retcode'] == 0
          return json['result']
        else
          QQBot::LOGGER.info "获取讨论组信息失败 返回码 #{json['retcode']}"
        end
      else
        QQBot::LOGGER.info "请求失败，返回码 #{code}"
      end
    end

    def hash
      self.class.hash(@options[:uin], @options[:ptwebqq])
    end

    def msg_id
      @msg_id += 1
    end

    def build_message(content)
      JSON.generate(
        [
            content,
            [
                'font',
                {
                    name: '宋体',
                    size: 10,
                    style: [0, 0, 0],
                    color: '000000'
                }
            ]
        ]
      )
    end
  end
end
