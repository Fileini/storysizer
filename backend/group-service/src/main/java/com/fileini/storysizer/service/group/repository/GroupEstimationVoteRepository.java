package com.fileini.storysizer.service.group.repository;

import com.fileini.storysizer.service.group.model.GroupEstimationVote;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface GroupEstimationVoteRepository extends JpaRepository<GroupEstimationVote, Long> {
    List<GroupEstimationVote> findByGroupEstimationId(Long groupEstimationId);
    List<GroupEstimationVote> findByUserIdAndStatus(String userId, String status);
    Optional<GroupEstimationVote> findByGroupEstimationIdAndUserId(Long groupEstimationId, String userId);
    long countByUserIdAndStatus(String userId, String status);
}
