package com.fileini.storysizer.service.estimation.model;

import jakarta.persistence.*;

@Entity
public class Estimation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String owner;
    private int complexity;
    private int reach;          // Relazione con Story (via Gateway GraphQL)
    private Long storyId;       // Riferimento alla Story
    private int dimensions;
    private int risk;
    private int interaction;

    // Costruttori, Getter e Setter
    public Estimation() {}

    public Estimation(String owner, int complexity, int reach, Long storyId, int dimensions, int risk, int interaction) {
        this.owner = owner;
        this.complexity = complexity;
        this.reach = reach;
        this.storyId = storyId;
        this.dimensions = dimensions;
        this.risk = risk;
        this.interaction = interaction;
    }

    // Getter e Setter
    public Long getId() { return id; }
    public String getOwner() { return owner; }
    public int getComplexity() { return complexity; }
    public int getReach() { return reach; }
    public Long getStoryId() { return storyId; }
    public int getDimensions() { return dimensions; }
    public int getRisk() { return risk; }
    public int getInteraction() { return interaction; }

    public void setId(Long id) { this.id = id; }
    public void setOwner(String owner) { this.owner = owner; }
    public void setComplexity(int complexity) { this.complexity = complexity; }
    public void setReach(int reach) { this.reach = reach; }
    public void setStoryId(Long storyId) { this.storyId = storyId; }
    public void setDimensions(int dimensions) { this.dimensions = dimensions; }
    public void setRisk(int risk) { this.risk = risk; }
    public void setInteraction(int interaction) { this.interaction = interaction; }
}
