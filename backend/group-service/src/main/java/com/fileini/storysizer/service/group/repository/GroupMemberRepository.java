package com.fileini.storysizer.service.group.repository;

import com.fileini.storysizer.service.group.model.GroupMember;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface GroupMemberRepository extends JpaRepository<GroupMember, Long> {
    List<GroupMember> findByUserId(String userId);
    List<GroupMember> findByGroupId(Long groupId);
    Optional<GroupMember> findByGroupIdAndUserId(Long groupId, String userId);
    boolean existsByGroupIdAndUserId(Long groupId, String userId);
}
