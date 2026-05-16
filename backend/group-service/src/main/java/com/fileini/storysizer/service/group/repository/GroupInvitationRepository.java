package com.fileini.storysizer.service.group.repository;

import com.fileini.storysizer.service.group.model.GroupInvitation;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface GroupInvitationRepository extends JpaRepository<GroupInvitation, Long> {
    List<GroupInvitation> findByGroupIdAndStatus(Long groupId, String status);
    Optional<GroupInvitation> findByTokenHash(String tokenHash);
    boolean existsByGroupIdAndInvitedEmailAndStatus(Long groupId, String invitedEmail, String status);
}
