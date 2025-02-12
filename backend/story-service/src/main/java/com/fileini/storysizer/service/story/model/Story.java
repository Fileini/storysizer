package com.fileini.storysizer.service.story.model;

import jakarta.persistence.*;

@Entity
public class Story {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
    private String owner;

    // Costruttori, Getter e Setter
    public Story() {}

    public Story(String name, String owner) {
        this.name = name;
        this.owner = owner;
    }

    public Long getId() { return id; }
    public String getName() { return name; }
    public String getOwner() { return owner; }

    public void setId(Long id) { this.id = id; }
    public void setName(String name) { this.name = name; }
    public void setOwner(String owner) { this.owner = owner; }
}
