package com.fileini.storysizer.service.story.controller;

import com.fileini.storysizer.service.story.model.Story;
import com.fileini.storysizer.service.story.repository.StoryRepository;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/stories")
public class StoryController {

    private final StoryRepository repository;

    public StoryController(StoryRepository repository) {
        this.repository = repository;
    }

    @GetMapping
    public List<Story> getAllStories() {
        return repository.findAll();
    }

    @GetMapping("/{id}")
    public Story getStoryById(@PathVariable Long id) {
        return repository.findById(id).orElseThrow();
    }

    @GetMapping("/owner/{owner}")
    public List<Story> getStoryByOwner(@PathVariable String owner, @RequestParam(required = false) Long id) {
        if (id == null){
            return repository.findAll()
            .parallelStream()
            .filter(s -> s.getOwner().equals(owner))
            .toList();
        } else 
        return repository.findAll()
        .parallelStream()
        .filter(s -> s.getOwner().equals(owner))
        .filter(s -> s.getId().equals(id))
        .toList();
    }

    @PostMapping
    public Story createStory(@RequestBody Story story) {
        return repository.save(story);
    }

    @PutMapping("/{id}")
    public Story updateStory(@PathVariable Long id, @RequestBody Story story) {
        story.setId(id);
        return repository.save(story);
    }

    @DeleteMapping("/{id}")
    public void deleteStory(@PathVariable Long id) {
        repository.deleteById(id);
    }
}
