package com.fileini.storysizer.service.group.repository;

import com.fileini.storysizer.service.group.model.SizingGroup;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface GroupRepository extends JpaRepository<SizingGroup, Long> {
    // Only return non-deleted groups
    Optional<SizingGroup> findByIdAndDeletedAtIsNull(Long id);
}
