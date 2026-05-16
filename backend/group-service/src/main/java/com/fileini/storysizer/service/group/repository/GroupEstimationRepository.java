package com.fileini.storysizer.service.group.repository;

import com.fileini.storysizer.service.group.model.GroupEstimation;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface GroupEstimationRepository extends JpaRepository<GroupEstimation, Long> {
    List<GroupEstimation> findByGroupIdOrderByCreatedAtDesc(Long groupId);
}
