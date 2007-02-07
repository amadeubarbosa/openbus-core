require "uuid"

local oop = require "loop.base"

Session = oop.class{
  membersByIdentifier = {},
  membersByName = {},
}

function Session:getIdentifier()
    return self.identifier
end

function Session:addMember(member)
    local memberName = member:getName()
    local memberIdentifier = self:generateMemberIdentifier()
    self.membersByIdentifier[memberIdentifier] = member
    self.membersByName[memberName] = member
end

function Session:removeMember(memberIdentifier)
    local member = self.membersByIdentifier[memberIdentifier]
    if not member then
        return false
    end
    local memberName = member:getName()
    self.membersByIdentifier[memberIdentifier] = nil
    self.membersByName[memberName] = nil
    return true
end

function Session:getMember(memberName)
    return self.membersByName[memberName]
end

function Session:getMembers()
    local members = {}
    for _, member in pairs(self.membersByIdentifier) do
        table.insert(members, member)
    end
    return members
end

function Session:generateMemberIdentifier()
    return uuid.new("time")
end
