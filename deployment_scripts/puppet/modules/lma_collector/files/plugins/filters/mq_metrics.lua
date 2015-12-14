-- Copyright 2015 Mirantis, Inc.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

require "string"
local dt     = require "date_time"
local l      = require 'lpeg'
l.locale(l)

local syslog = require "syslog"
local patt   = require 'patterns'
local utils  = require 'lma_utils'

local om_grammar = patt.anywhere(l.Ct(l.P"oslo_messaging._drivers.amqpdriver"))
local om_size_grammar = patt.anywhere(l.Ct(l.P"size: " * l.Cg(l.digit^1, "mq_message_size")))
local om_topic_grammar = patt.anywhere(l.Ct(l.P"topic: " * l.Cg(l.P(1)^1, "mq_topic")))



local msg = {
    Type = "metric", -- will be prefixed by "heka.sandbox."
    Timestamp = nil,
    Severity = 6,
    Fields = nil
}

function process_message ()
    local payload = read_message("Payload")

    local mq_message_size = nil
    local mq_topic = nil

    m = om_grammar:match(payload)
    if m then
        m = om_size_grammar:match(payload)
        if m then
            mq_message_size = m.mq_message_size
        end
        m = om_topic_grammar:match(payload)
        if m then
            mq_topic = m.mq_topic
        end
    end

    -- local mq_message_size = read_message("Fields[mq_message_size]")
    -- local mq_topic = read_message("Fields[mq_topic]")

    if mq_message_size == nil or mq_topic == nil then
        return -1
    end

    -- keep only the first 2 tokens because some services like Neutron report
    -- themselves as 'openstack.<service>.server'
    local service = string.gsub(read_message("Logger"), '(%w+)%.(%w+).*', '%1_%2')

    msg.Timestamp = read_message("Timestamp")
    msg.Fields = {
        hostname = read_message("Hostname"),
        source = read_message('Fields[programname]') or service,
        name = service .. '_mq',
        type = utils.metric_type['GAUGE'],
        value = {value = mq_message_size, representation = 's'},
        tenant_id = read_message('Fields[tenant_id]'),
        user_id = read_message('Fields[user_id]'),
        mq_topic = mq_topic,
        tag_fields = {'mq_topic'},
    }
    utils.inject_tags(msg)
    return utils.safe_inject_message(msg)
end
