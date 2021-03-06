"""
    showgeometry!(scene, vs, ns; arrow = 0.5)

Show pointcloud with normals.
"""
function showgeometry!(scene, vs::Array{SVector{3,F},1}, ns::Array{SVector{3,F},1}; arrow = 0.5, kwargs...) where F
    plns = normalsforplot(vs, ns, arrow)
    scatter!(scene, vs; kwargs...)
    linesegments!(scene, plns, color = :blue)
    #cam3d!(scene)
    scene
end

function showgeometry!(scene, vs, ns; arrow = 0.5, kwargs...)
    vsn = [SVector{3, Float64}(i) for i in vs]
    nsn = [SVector{3, Float64}(i) for i in ns]
    showgeometry!(scene, vsn, nsn; arrow=arrow, kwargs...)
end

function showgeometry!(scene, m; arrow = 0.5, kwargs...)
    vsn = [SVector{3, Float64}(i) for i in m.vertices]
    nsn = [SVector{3, Float64}(i) for i in m.normals]
    showgeometry!(scene, vsn, nsn; arrow=arrow, kwargs...)
end

function showgeometry(m; arrow=0.5, kwargs...)
    s = Scene()
    showgeometry!(s, m; arrow=arrow, kwargs...)
end

function showgeometry(vs, ns; arrow=0.5, kwargs...)
    s = Scene()
    showgeometry!(s, vs, ns; arrow=arrow, kwargs...)
end

function showcandlength(ck)
    for c in ck
        println("candidate length: $(length(c.inpoints))")
    end
end

function showshapes!(s, pointcloud, candidateA; plotleg=true, texts=nothing, kwargs...)
    colscheme = ColorSchemes.gnuplot
    colA = get.(Ref(colscheme), range(0, stop=1, length=(size(candidateA,1)+1)))
    colA = deleteat!(colA, 1)
    texts_ = []
    for i in 1:length(candidateA)
        ind = candidateA[i].inpoints
        push!(texts_, RANSAC.strt(candidateA[i].candidate.shape)*"$i")
        scatter!(s, pointcloud.vertices[ind], color = colA[i]; kwargs...)
    end

    usetexts = texts === nothing ? texts_ : texts
    if plotleg
        if s.attributes[:show_axis][]
            sl = legend(s.plots[2:end], usetexts)
        else
            sl = legend(s.plots, usetexts)
        end
        sn = Scene(clear=false, show_axis = false, resolution=(1920,1080))
        sn.center=false
        return vbox(s, sl, parent=sn)
    else
        return s
    end
end

function showshapes(pointcloud, candidateA; plotleg=true, kwargs...)
    sc = Scene()
    showshapes!(sc, pointcloud, candidateA; plotleg=plotleg, kwargs...)
end

function getrest(pc)
    return findall(pc.isenabled)
end


function showtype(l)
    for t in l
        println(t.candidate.shape)
    end
end

function showbytype!(s, pointcloud, candidateA, plotleg=true; kwargs...)
    colors_ = []
    texts_ = []
    for i in eachindex(candidateA)
        c = candidateA[i]
        ind = c.inpoints
        if c.candidate.shape isa FittedCylinder
            colour = :red
            push!(colors_, :red)
            push!(texts_, "Cylinder$i")
        elseif c.candidate.shape isa FittedSphere
            colour = :green
            push!(colors_, :green)
            push!(texts_, "Sphere$i")
        elseif c.candidate.shape isa FittedPlane
            colour = :orange
            push!(colors_, :orange)
            push!(texts_, "Plane$i")
        elseif c.candidate.shape isa FittedCone
            colour = :blue
            push!(colors_, :blue)
            push!(texts_, "Cone$i")
        elseif c.candidate.shape isa AbstractTranslationalSurface
            colour = :purple
            push!(colors_, :purple)
            push!(texts_, "Translational$i")
        end
        scatter!(s, pointcloud.vertices[ind], color = colour; kwargs...)
    end
    if plotleg
        if s.attributes[:show_axis][]
            sl = legend(s.plots[2:end], texts_)
        else
            sl = legend(s.plots, texts_)
        end
        sn = Scene(clear=false, show_axis = false, resolution=(1920,1080))
        sn.center=false
        return vbox(s, sl, parent=sn)
    else
        return s
    end
end

function showbytype(pointcloud, candidateA, plotleg=true; kwargs...)
    sc = Scene()
    showbytype!(sc, pointcloud, candidateA, plotleg; kwargs...)
end

function plotshape(shape::FittedShape; kwargs...)
    plotshape!(Scene(), shape; kwargs...)
end

function plotshape!(sc, shape::FittedPlane; scale=(1.,1.), color=(:blue, 0.1))
    # see project2plane
    o_z = normalize(shape.normal)
    o_x = normalize(arbitrary_orthogonal2(o_z))
    o_y = normalize(cross(o_z, o_x))

    p1 = shape.point
    p2 = p1 + scale[1]*o_x
    p3 = p1 + scale[1]*o_x + scale[2]*o_y
    p4 = p1 + scale[2]*o_y

    mesh!(sc, [p1,p2,p3], color=color, transparency=true)
    mesh!(sc, [p1,p3,p4], color=color, transparency=true)
    sc
end

function plotshape!(sc, shape::FittedSphere; scale=(1.,), color=(:blue, 0.1))
    mesh!(sc, Sphere(Point(shape.center), scale[1]*shape.radius), color=color, transparency=true)
end

function plotshape!(sc, shape::FittedCylinder; scale=(1.,), color=(:blue, 0.1))
    o = Point(shape.center)
    extr = o+scale[1]*Point(normalize(shape.axis))
    mesh!(sc, Cylinder(o, extr, shape.radius), color=color, transparency=true)
end

function shiftplane!(sc, p::FittedPlane, dist; kwargs...)
    newo = p.point+dist*normalize(p.normal)
    newp = FittedPlane(true, newo, p.normal)
    plotshape!(sc, newp; kwargs...)
end

function plotimplshape!(sc, shape::ImplicitPlane; scale=(1.,1.), color=(:blue, 0.1))
    fp = FittedPlane(true, shape.point, shape.normal)
    plotshape!(sc, fp; scale=scale, color=color)
end

function plotimplshape!(sc, shape::ImplicitSphere; scale=(1.,1.), color=(:blue, 0.1))
    fs = FittedSphere(true, shape.center, shape.radius, true)
    plotshape!(sc, fs; scale=scale, color=color)
end

function plotimplshape!(sc, shape::ImplicitCylinder; scale=(1.,1.), color=(:blue, 0.1))
    fc = FittedCylinder(true, shape.axis, shape.center, shape.radius, true)
    plotshape!(sc, fc; scale=scale, color=color)
end

function plotimplshape!(sc, shape::ImplicitTranslational; scale=(1.,1.), color=(:blue, 0.1))
    @warn "Plotting of ImplicitTranslational is not implemented yet!"
    return sc
end

function plotimplshape(shape::CSGBuilding.AbstractImplicitSurface; scale=(1.,1.), color=(:blue, 0.1))
    s = Scene()
    plotimplshape!(s, shape; scale=scale, color=color)
end

function givelargest(scoredshapes)
    sizes = [size(s.inpoints, 1) for s in scoredshapes]
    mind = argmax(sizes)
    println("Best: $mind. - $(scoredshapes[mind])")
    return scoredshapes[mind]
end

"""
    drawcircles!(sc, points, r; kwargs...)

Use `strokecolor=:blue` or what you want.
"""
function drawcircles!(sc, points, r; kwargs...)
    ps = [Makie.Point2f0(p) for p in points]
    poly!(sc, [Circle(p, Float32(r)) for p in ps], color = (:blue, 0.0), transparency = true, strokewidth=1; kwargs...)
    sc
end

function wframe(ps, trs; kwargs...)
	vrts = [Point3(i[1], i[2], 0.) for i in ps]
	fces = [Face{3,Int}(i) for i in trs]
	tm = HomogenousMesh(vrts, fces, [], [], [], [], [])
	Makie.wireframe(tm; kwargs...)
end

function plotspantree!(s, points, tree; kwargs...)
	for (i, obj) in enumerate(tree)
		p2 = points[obj]
		lines!(s, (x->x[1]).(p2), (x->x[2]).(p2); kwargs...)
	end
	s
end
