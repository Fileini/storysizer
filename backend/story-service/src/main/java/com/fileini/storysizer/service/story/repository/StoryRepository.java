package com.fileini.storysizer.service.story.repository;

import com.fileini.storysizer.service.story.model.Story;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StoryRepository extends JpaRepository<Story, Long> {}
